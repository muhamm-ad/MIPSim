#!/usr/bin/env python3
"""Unit tests for tools/asm.py. Run with: python3 -m unittest discover -s tools -v

Reference encodings below were computed by hand from the MIPS Green Sheet
(Docs/MIPS_Green_Sheet.pdf), not with the assembler under test.
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import asm  # noqa: E402


def words(source):
    return asm.assemble(source)[0]


class EncodingTests(unittest.TestCase):
    def test_r_type(self):
        self.assertEqual(words("add $t0, $t1, $t2"), [0x012A4020])
        self.assertEqual(words("addu $t0, $t1, $t2"), [0x012A4021])
        self.assertEqual(words("sub $t0, $t1, $t2"), [0x012A4022])
        self.assertEqual(words("subu $t0, $t1, $t2"), [0x012A4023])
        self.assertEqual(words("and $t0, $t1, $t2"), [0x012A4024])
        self.assertEqual(words("or $t0, $t1, $t2"), [0x012A4025])
        self.assertEqual(words("nor $t0, $t1, $t2"), [0x012A4027])
        self.assertEqual(words("slt $t0, $t1, $t2"), [0x012A402A])
        self.assertEqual(words("xor $t0, $t1, $t2"), [0x012A4026])
        self.assertEqual(words("sltu $t0, $t1, $t2"), [0x012A402B])

    def test_shifts(self):
        self.assertEqual(words("sll $t0, $t1, 4"), [0x00094100])
        self.assertEqual(words("srl $t0, $t1, 31"), [0x000947C2])
        self.assertEqual(words("sra $t0, $t1, 1"), [0x00094043])
        self.assertEqual(words("sll $0, $0, 0"), [0x00000000])  # nop

    def test_immediates(self):
        self.assertEqual(words("addi $v0, $0, 5"), [0x20020005])
        self.assertEqual(words("addi $t0, $zero, -1"), [0x2008FFFF])
        self.assertEqual(words("addi $a3, $v1, -9"), [0x2067FFF7])
        self.assertEqual(words("addiu $t0, $t0, 1"), [0x25080001])
        self.assertEqual(words("ori $t0, $t0, 0xFF"), [0x350800FF])
        self.assertEqual(words("andi $t0, $t1, 0x8000"), [0x31288000])
        self.assertEqual(words("slti $t0, $t1, 10"), [0x2928000A])
        self.assertEqual(words("sltiu $t0, $t1, -1"), [0x2D28FFFF])
        self.assertEqual(words("xori $t0, $t1, 0xFF"), [0x392800FF])
        self.assertEqual(words("lui $t0, 0x1234"), [0x3C081234])
        self.assertEqual(words("lui $t0, 0xFFFF"), [0x3C08FFFF])

    def test_memory(self):
        self.assertEqual(words("lw $t0, 4($sp)"), [0x8FA80004])
        self.assertEqual(words("sw $ra, 0($sp)"), [0xAFBF0000])
        self.assertEqual(words("lw $t1, -4($sp)"), [0x8FA9FFFC])
        self.assertEqual(words("sw $t1, ($sp)"), [0xAFA90000])
        self.assertEqual(words("lw $t0, 0x10($t1)"), [0x8D280010])

    def test_register_names_and_numbers(self):
        self.assertEqual(words("add $8, $9, $10"), words("add $t0, $t1, $t2"))
        self.assertEqual(words("add $zero, $zero, $zero"), [0x00000020])

    def test_branches_use_pc_relative_word_offsets(self):
        # beq at 0x08 jumping back to 0x00: (0x00 - (0x08 + 4)) / 4 = -3
        src = "top: nop\n nop\n beq $t0, $t1, top"
        self.assertEqual(words(src)[2], 0x1109FFFD)
        # bne at 0x00 to 0x08: (0x08 - 4) / 4 = 1
        src = "bne $t0, $0, end\n nop\nend: nop"
        self.assertEqual(words(src)[0], 0x15000001)
        # branch to the next instruction has offset 0
        src = "beq $0, $0, next\nnext: nop"
        self.assertEqual(words(src)[0], 0x10000000)
        # raw numeric offset
        self.assertEqual(words("beq $0, $0, 3"), [0x10000003])

    def test_jump(self):
        src = "nop\nnop\ntarget: nop\n j target"
        self.assertEqual(words(src)[3], 0x08000002)  # 0x08 >> 2
        self.assertEqual(words("j top\n" + "nop\n" * 63 + "top: nop")[0], 0x08000040)

    def test_pseudo_instructions(self):
        self.assertEqual(words("nop"), [0x00000000])
        self.assertEqual(words("move $t0, $t1"), [0x01204021])  # addu $t0,$t1,$0
        self.assertEqual(words("li $t0, 5"), [0x20080005])  # addi
        self.assertEqual(words("li $t0, -5"), [0x2008FFFB])
        self.assertEqual(words("li $t0, 0xFFFF"), [0x3408FFFF])  # ori (does not fit signed)
        self.assertEqual(words("not $t0, $t1"), [0x01204027])  # nor $t0,$t1,$0
        self.assertEqual(words("neg $t0, $t1"), [0x00094022])  # sub $t0,$0,$t1
        self.assertEqual(words("top: b top"), [0x1000FFFF])  # beq $0,$0,top
        self.assertEqual(words("nop\nnop\nhalt"), [0, 0, 0x08000002])  # j to itself

    def test_li_with_32_bit_constants(self):
        self.assertEqual(words("li $t0, 0x12345678"), [0x3C081234, 0x35085678])  # lui + ori
        self.assertEqual(words("li $t0, 0x10000"), [0x3C080001])  # low half is zero: lui only
        self.assertEqual(words("li $t0, 65536"), [0x3C080001])
        self.assertEqual(words("li $t0, -32769"), [0x3C08FFFF, 0x35087FFF])
        self.assertEqual(words("li $t0, 0xFFFFFFFF"), [0x3C08FFFF, 0x3508FFFF])
        self.assertEqual(words("li $t0, -2147483648"), [0x3C088000])

    def test_multiword_li_shifts_following_label_addresses(self):
        # the 2-word li moves 'here' to 0x08, so the branch at 0x08 back to 'top' is -3
        src = "top: li $t0, 0x12345678\nhere: beq $0, $0, top\n j here"
        w = words(src)
        self.assertEqual(w[2], 0x1000FFFD)
        self.assertEqual(w[3], 0x08000002)  # j to 0x08

    def test_word_directive_and_ignored_directives(self):
        self.assertEqual(words(".text\n.globl main\n.word 0xDEADBEEF\n.word -1"),
                         [0xDEADBEEF, 0xFFFFFFFF])

    def test_labels_on_their_own_line_and_before_instructions(self):
        src = "a:\nb: nop\nc: d: nop\n j d"
        self.assertEqual(words(src)[2], 0x08000001)

    def test_comments_and_blank_lines(self):
        self.assertEqual(words("# only a comment\n\n   addi $t0, $0, 1   # trailing\n"), [0x20080001])

    def test_case_insensitive_mnemonics(self):
        self.assertEqual(words("ADD $t0, $t1, $t2"), [0x012A4020])


class ErrorTests(unittest.TestCase):
    def assert_error(self, source, fragment, lineno=None):
        with self.assertRaises(asm.AsmError) as ctx:
            asm.assemble(source)
        self.assertIn(fragment, str(ctx.exception))
        if lineno is not None:
            self.assertEqual(ctx.exception.lineno, lineno)

    def test_unknown_instruction(self):
        self.assert_error("nop\nfoo $t0", "unknown instruction", 2)

    def test_unknown_register(self):
        self.assert_error("add $t0, $t1, $xx", "unknown register", 1)
        self.assert_error("add $t0, $t1, $32", "unknown register", 1)
        self.assert_error("add $t0, $t1, t2", "expected a register", 1)

    def test_operand_count(self):
        self.assert_error("add $t0, $t1", "takes 3 operand", 1)

    def test_immediate_range(self):
        self.assert_error("addi $t0, $0, 32768", "does not fit", 1)
        self.assert_error("addi $t0, $0, -32769", "does not fit", 1)
        self.assert_error("ori $t0, $0, -1", "does not fit", 1)
        self.assert_error("ori $t0, $0, 65536", "does not fit", 1)
        self.assert_error("li $t0, 0x100000000", "does not fit in 32 bits", 1)
        self.assert_error("li $t0, -2147483649", "does not fit in 32 bits", 1)
        self.assert_error("lui $t0, 65536", "does not fit", 1)
        self.assert_error("lui $t0, -1", "does not fit", 1)
        self.assert_error("sll $t0, $t1, 32", "out of range", 1)
        self.assert_error("srl $t0, $t1, -1", "out of range", 1)

    def test_undefined_and_duplicate_labels(self):
        self.assert_error("j nowhere", "undefined label", 1)
        self.assert_error("a: nop\na: nop", "defined twice", 2)

    def test_bad_memory_operand(self):
        self.assert_error("lw $t0, $t1", "offset(register)", 1)

    def test_not_an_integer(self):
        self.assert_error("addi $t0, $0, five", "expected an integer", 1)

    def test_branch_out_of_range(self):
        body = "nop\n" * 40000
        self.assert_error("beq $0, $0, far\n" + body + "far: nop", "does not fit", 1)


class ExpectTests(unittest.TestCase):
    def test_expect_directives(self):
        src = "nop  # expect MEM[0x54] = 7\n# expect MEM[8]=-1\n# expect mem[ 0x10 ] = 0x20\n"
        _, _, expects = asm.assemble(src)
        self.assertEqual(expects, [(0x54, 7), (8, 0xFFFFFFFF), (0x10, 0x20)])

    def test_expect_must_be_word_aligned(self):
        with self.assertRaises(asm.AsmError):
            asm.assemble("# expect MEM[0x55] = 1")

    def test_output_formats(self):
        words_, listing, expects = asm.assemble("addi $v0, $0, 5\n# expect MEM[4] = 3\n")
        self.assertEqual(asm.hex_text(listing), "20020005  # 0x0000: addi $v0, $0, 5\n")
        self.assertIn("00000004 00000003", asm.expect_text(expects))


if __name__ == "__main__":
    unittest.main()
