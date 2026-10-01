#!/usr/bin/env python3
"""Minimal MIPS assembler for MIPSim.

Turns a MIPS assembly file into the hex program format read by hdl_export/imem.vhd
(one 32-bit word per line, 8 hex digits) and, optionally, a file of expected final
memory contents used by tb/tb_mips.vhd.

Supported instructions (see Docs/Supported_Instruction.md):
    add addu sub subu and or nor slt        rd, rs, rt
    addi addiu slti                         rt, rs, imm   (imm: -32768..32767)
    andi ori                                rt, rs, imm   (imm: 0..65535)
    lw sw                                   rt, imm(rs)
    beq bne                                 rs, rt, label
    j                                       label
Pseudo-instructions:
    nop                 sll $0,$0,0 (all-zero word)
    move rd, rs         addu rd, rs, $0
    li rt, imm          addi rt,$0,imm  or  ori rt,$0,imm  (16-bit constants only)
    halt                j <this instruction>: the PC stops moving, which the testbench
                        detects as the end of the program
Directives:
    .word value         emit a raw 32-bit word
    .text/.globl/.data  accepted and ignored
Comments start with '#'. Labels are 'name:' (alone or before an instruction).

Test expectations are written in comments and ignored by the assembler proper:
    # expect MEM[0x54] = 7
means: when the program has halted, the word at byte address 0x54 of the data
memory must contain 7.

Usage:
    asm.py prog.s                     writes prog.hex (+ prog.expect if any expect)
    asm.py prog.s -o out.hex --expect out.expect
    asm.py prog.s -l                  also print a listing
"""

import argparse
import os
import re
import sys

REGISTERS = {
    "zero": 0, "at": 1, "v0": 2, "v1": 3, "a0": 4, "a1": 5, "a2": 6, "a3": 7,
    "t0": 8, "t1": 9, "t2": 10, "t3": 11, "t4": 12, "t5": 13, "t6": 14, "t7": 15,
    "s0": 16, "s1": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23,
    "t8": 24, "t9": 25, "k0": 26, "k1": 27, "gp": 28, "sp": 29, "fp": 30, "ra": 31,
}

R_FUNCT = {
    "add": 0x20, "addu": 0x21, "sub": 0x22, "subu": 0x23,
    "and": 0x24, "or": 0x25, "nor": 0x27, "slt": 0x2A,
}
# mnemonic -> (opcode, signed immediate?)
I_ARITH = {
    "addi": (0x08, True), "addiu": (0x09, True), "slti": (0x0A, True),
    "andi": (0x0C, False), "ori": (0x0D, False),
}
MEM_OP = {"lw": 0x23, "sw": 0x2B}
BRANCH_OP = {"beq": 0x04, "bne": 0x05}
J_OP = {"j": 0x02}
PSEUDO = {"nop", "move", "li", "halt"}
DIRECTIVES_IGNORED = {".text", ".data", ".globl", ".global", ".set"}

EXPECT_RE = re.compile(r"#\s*expect\s+MEM\[\s*([^\]\s]+)\s*\]\s*=\s*(\S+)", re.IGNORECASE)
MEM_OPERAND_RE = re.compile(r"^([-+]?\w*)\(\s*(\$?\w+)\s*\)$")
LABEL_RE = re.compile(r"^([A-Za-z_.][\w.]*)\s*:")


class AsmError(Exception):
    def __init__(self, message, lineno=None):
        super().__init__(message)
        self.lineno = lineno


def parse_register(token, lineno):
    name = token.strip()
    if not name.startswith("$"):
        raise AsmError(f"expected a register, got '{token}'", lineno)
    name = name[1:]
    if name.isdigit():
        number = int(name)
        if 0 <= number <= 31:
            return number
    elif name in REGISTERS:
        return REGISTERS[name]
    raise AsmError(f"unknown register '{token}'", lineno)


def parse_int(token, lineno):
    try:
        return int(token.strip(), 0)
    except ValueError:
        raise AsmError(f"expected an integer, got '{token}'", lineno) from None


def check_imm(value, signed, lineno):
    low, high = (-32768, 32767) if signed else (0, 65535)
    if not low <= value <= high:
        kind = "signed" if signed else "unsigned"
        raise AsmError(f"immediate {value} does not fit in 16 bits ({kind}: {low}..{high})", lineno)
    return value & 0xFFFF


def r_type(rs, rt, rd, shamt, funct):
    return (rs << 21) | (rt << 16) | (rd << 11) | (shamt << 6) | funct


def i_type(op, rs, rt, imm16):
    return (op << 26) | (rs << 21) | (rt << 16) | imm16


class Statement:
    """One source line that emits a word: mnemonic, operands, address, source text."""

    def __init__(self, mnemonic, operands, address, lineno, text):
        self.mnemonic = mnemonic
        self.operands = operands
        self.address = address
        self.lineno = lineno
        self.text = text


def split_operands(rest):
    rest = rest.strip()
    if not rest:
        return []
    return [part.strip() for part in rest.split(",")]


def first_pass(source):
    """Collect statements, labels and `expect` directives."""
    statements = []
    labels = {}
    expects = []
    address = 0
    for lineno, raw in enumerate(source.splitlines(), start=1):
        match = EXPECT_RE.search(raw)
        if match:
            addr = parse_int(match.group(1), lineno)
            value = parse_int(match.group(2), lineno)
            if addr % 4 != 0:
                raise AsmError(f"expect address {addr:#x} is not word aligned", lineno)
            expects.append((addr & 0xFFFFFFFF, value & 0xFFFFFFFF))
        line = raw.split("#", 1)[0].strip()
        while True:
            label = LABEL_RE.match(line)
            if not label:
                break
            name = label.group(1)
            if name in labels:
                raise AsmError(f"label '{name}' defined twice", lineno)
            labels[name] = address
            line = line[label.end():].strip()
        if not line:
            continue
        parts = line.split(None, 1)
        mnemonic = parts[0].lower()
        operands = split_operands(parts[1]) if len(parts) > 1 else []
        if mnemonic in DIRECTIVES_IGNORED:
            continue
        statements.append(Statement(mnemonic, operands, address, lineno, line))
        address += 4
    return statements, labels, expects


def expect_operands(stmt, count):
    if len(stmt.operands) != count:
        raise AsmError(
            f"'{stmt.mnemonic}' takes {count} operand(s), got {len(stmt.operands)}", stmt.lineno)


def resolve_target(token, labels, lineno):
    if token in labels:
        return labels[token]
    raise AsmError(f"undefined label '{token}'", lineno)


def encode(stmt, labels):
    m, ops, ln = stmt.mnemonic, stmt.operands, stmt.lineno

    if m in R_FUNCT:
        expect_operands(stmt, 3)
        rd, rs, rt = (parse_register(o, ln) for o in ops)
        return r_type(rs, rt, rd, 0, R_FUNCT[m])

    if m in I_ARITH:
        expect_operands(stmt, 3)
        op, signed = I_ARITH[m]
        rt, rs = parse_register(ops[0], ln), parse_register(ops[1], ln)
        return i_type(op, rs, rt, check_imm(parse_int(ops[2], ln), signed, ln))

    if m in MEM_OP:
        expect_operands(stmt, 2)
        rt = parse_register(ops[0], ln)
        match = MEM_OPERAND_RE.match(ops[1].replace(" ", ""))
        if not match:
            raise AsmError(f"expected 'offset(register)', got '{ops[1]}'", ln)
        offset = parse_int(match.group(1), ln) if match.group(1) not in ("", "+", "-") else 0
        rs = parse_register(match.group(2), ln)
        return i_type(MEM_OP[m], rs, rt, check_imm(offset, True, ln))

    if m in BRANCH_OP:
        expect_operands(stmt, 3)
        rs, rt = parse_register(ops[0], ln), parse_register(ops[1], ln)
        try:
            offset = int(ops[2], 0)  # raw word offset
        except ValueError:
            target = resolve_target(ops[2], labels, ln)
            delta = target - (stmt.address + 4)
            offset = delta // 4
        return i_type(BRANCH_OP[m], rs, rt, check_imm(offset, True, ln))

    if m in J_OP:
        expect_operands(stmt, 1)
        target = resolve_target(ops[0], labels, ln)
        if (target & 0xF0000000) != ((stmt.address + 4) & 0xF0000000):
            raise AsmError("jump target is outside the current 256 MiB region", ln)
        return (J_OP[m] << 26) | ((target >> 2) & 0x3FFFFFF)

    if m == "nop":
        expect_operands(stmt, 0)
        return 0
    if m == "move":
        expect_operands(stmt, 2)
        rd, rs = parse_register(ops[0], ln), parse_register(ops[1], ln)
        return r_type(rs, 0, rd, 0, R_FUNCT["addu"])
    if m == "li":
        expect_operands(stmt, 2)
        rt, value = parse_register(ops[0], ln), parse_int(ops[1], ln)
        if -32768 <= value <= 32767:
            return i_type(I_ARITH["addi"][0], 0, rt, value & 0xFFFF)
        if 32768 <= value <= 65535:
            return i_type(I_ARITH["ori"][0], 0, rt, value)
        raise AsmError(f"li: {value} does not fit in 16 bits (no lui available)", ln)
    if m == "halt":
        expect_operands(stmt, 0)
        return (J_OP["j"] << 26) | ((stmt.address >> 2) & 0x3FFFFFF)
    if m == ".word":
        expect_operands(stmt, 1)
        return parse_int(ops[0], ln) & 0xFFFFFFFF

    raise AsmError(f"unknown instruction '{m}'", ln)


def assemble(source):
    """Return (words, listing, expects) for an assembly source string.

    listing is a list of (byte address, word, source text) tuples.
    """
    statements, labels, expects = first_pass(source)
    words = []
    listing = []
    for stmt in statements:
        word = encode(stmt, labels)
        words.append(word)
        listing.append((stmt.address, word, stmt.text))
    return words, listing, expects


def hex_text(listing):
    return "".join(f"{word:08X}  # {addr:#06x}: {text}\n" for addr, word, text in listing)


def expect_text(expects):
    lines = ["# Expected final data memory: <byte address> <value>\n"]
    lines += [f"{addr:08X} {value:08X}  # MEM[{addr:#x}] = {value}\n" for addr, value in expects]
    return "".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description="MIPSim assembler")
    parser.add_argument("source", help="assembly source file")
    parser.add_argument("-o", "--output", help="hex output file (default: <source>.hex)")
    parser.add_argument("--expect", help="expectation output file (default: <source>.expect)")
    parser.add_argument("-l", "--listing", action="store_true", help="print a listing")
    args = parser.parse_args(argv)

    stem = os.path.splitext(args.source)[0]
    out_hex = args.output or stem + ".hex"
    out_expect = args.expect or stem + ".expect"

    with open(args.source, encoding="utf-8") as f:
        source = f.read()
    try:
        words, listing, expects = assemble(source)
    except AsmError as err:
        where = f"{args.source}:{err.lineno}" if err.lineno else args.source
        print(f"{where}: error: {err}", file=sys.stderr)
        return 1

    with open(out_hex, "w", encoding="utf-8") as f:
        f.write(hex_text(listing))
    if expects:
        with open(out_expect, "w", encoding="utf-8") as f:
            f.write(expect_text(expects))
    if args.listing:
        for addr, word, text in listing:
            print(f"{addr:08x}: {word:08x}  {text}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
