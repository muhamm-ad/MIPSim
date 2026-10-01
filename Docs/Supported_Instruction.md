# Supported Instruction

### BASIC INSTRUCTION FORMATS

| R   | opcode | rs    | rt    | rd    | shamt | funct |
| --- | ------ | ----- | ----- | ----- | ----- | ----- |
|     | 31-26  | 25-21 | 20-16 | 15-11 | 10-6  | 5-0   |

| I   | opcode | rs    | rt    | immediate |
| --- | ------ | ----- | ----- | --------- |
|     | 31-26  | 25-21 | 20-16 | 15-0      |

| J   | opcode | address |
| --- | ------ | ------- |
|     | 31-26  | 25-0    |

### SUPPORTED INSTRUCTION SET

For R-type instructions the opcode is `0x00` and the table gives the `funct` field; for I- and J-type instructions it gives the opcode.

| Name                     | Mnemonic | Format | Opcode / Funct | Operation                                  |
|:------------------------:|:--------:|:------:|:--------------:|:------------------------------------------:|
| Add                      | `add`    | R      | 0x20           | R[rd] = R[rs] + R[rt]                      |
| Add Unsigned             | `addu`   | R      | 0x21           | R[rd] = R[rs] + R[rt]                      |
| Subtract                 | `sub`    | R      | 0x22           | R[rd] = R[rs] - R[rt]                      |
| Subtract Unsigned        | `subu`   | R      | 0x23           | R[rd] = R[rs] - R[rt]                      |
| And                      | `and`    | R      | 0x24           | R[rd] = R[rs] & R[rt]                      |
| Or                       | `or`     | R      | 0x25           | R[rd] = R[rs] \| R[rt]                     |
| Xor                      | `xor`    | R      | 0x26           | R[rd] = R[rs] ^ R[rt]                      |
| Nor                      | `nor`    | R      | 0x27           | R[rd] = ~ (R[rs] \| R[rt])                 |
| Set Less Than            | `slt`    | R      | 0x2A           | R[rd] = (R[rs] < R[rt]) ? 1 : 0  (signed)  |
| Set Less Than Unsigned   | `sltu`   | R      | 0x2B           | R[rd] = (R[rs] < R[rt]) ? 1 : 0  (unsigned)|
| Shift Left Logical       | `sll`    | R      | 0x00           | R[rd] = R[rt] << shamt                     |
| Shift Right Logical      | `srl`    | R      | 0x02           | R[rd] = R[rt] >> shamt  (zero fill)        |
| Shift Right Arithmetic   | `sra`    | R      | 0x03           | R[rd] = R[rt] >>> shamt (sign fill)        |
| Jump Register            | `jr`     | R      | 0x08           | PC = R[rs]                                 |
| Add Immediate            | `addi`   | I      | 0x08           | R[rt] = R[rs] + SignExtImm                 |
| Add Immediate Unsigned   | `addiu`  | I      | 0x09           | R[rt] = R[rs] + SignExtImm                 |
| Set Less Than Immediate  | `slti`   | I      | 0x0A           | R[rt] = (R[rs] < SignExtImm) ? 1 : 0       |
| Set Less Than Imm. Uns.  | `sltiu`  | I      | 0x0B           | R[rt] = (R[rs] < SignExtImm) ? 1 : 0 (unsigned compare of the sign-extended immediate) |
| And Immediate            | `andi`   | I      | 0x0C           | R[rt] = R[rs] & ZeroExtImm                 |
| Or Immediate             | `ori`    | I      | 0x0D           | R[rt] = R[rs] \| ZeroExtImm                |
| Xor Immediate            | `xori`   | I      | 0x0E           | R[rt] = R[rs] ^ ZeroExtImm                 |
| Load Upper Immediate     | `lui`    | I      | 0x0F           | R[rt] = {imm, 16'b0}                       |
| Load Word                | `lw`     | I      | 0x23           | R[rt] = M[R[rs]+SignExtImm]                |
| Store Word               | `sw`     | I      | 0x2B           | M[R[rs]+SignExtImm] = R[rt]                |
| Branch On Equal          | `beq`    | I      | 0x04           | if (R[rs] == R[rt]) PC = PC+4 + BranchAddr |
| Branch On Not Equal      | `bne`    | I      | 0x05           | if (R[rs] != R[rt]) PC = PC+4 + BranchAddr |
| Jump                     | `j`      | J      | 0x02           | PC = JumpAddr                              |
| Jump And Link            | `jal`    | J      | 0x03           | R[31] = PC+4; PC = JumpAddr                |

with `SignExtImm = {16{imm[15]}, imm}`, `ZeroExtImm = {16'b0, imm}`, `BranchAddr = {14{imm[15]}, imm, 2'b0}` and `JumpAddr = {(PC+4)[31:28], address, 2'b0}`.

### Architectural notes

* Single cycle, one instruction per clock. There is **no branch delay slot**: the instruction following a taken branch or a jump is not executed.
* **No exceptions.** `add`, `addi` and `sub` do not trap on overflow and behave as `addu`, `addiu` and `subu`. An undefined **opcode** is executed as a no-op that writes nothing, neither a register nor memory. An R-type instruction with an undefined **`funct`** is not trapped either: the ALU returns all ones, which is written to `rd` (a reserved-instruction exception would be needed to do better).
* `$0` always reads as zero; writes to it are ignored. `sll $0, $0, 0` is the all-zero word, i.e. `nop`.
* Memory is accessed by **word only**, with byte addresses: the data memory is indexed by `address[31:2]` and the low two bits are ignored. A read outside the memory returns 0 and a write outside it is ignored. The instruction memory is indexed by `PC[ADDR_SIZE+1:2]`.
* Not implemented (yet): byte / half-word loads and stores, `mult` / `div` / `mfhi` / `mflo`, `sllv` / `srlv` / `srav`, `jalr`, the other conditional branches (`bltz`, `bgez`, `blez`, `bgtz`), exceptions and interrupts.

### Assembler pseudo-instructions

`tools/asm.py` accepts these in addition to the instructions above:

| Pseudo-instruction | Expansion                                                                         |
|:------------------:|:---------------------------------------------------------------------------------:|
| `nop`              | `sll $0, $0, 0` (0x00000000)                                                      |
| `move rd, rs`      | `addu rd, rs, $0`                                                                 |
| `li rt, imm`       | `addi rt, $0, imm` (-32768..32767), `ori rt, $0, imm` (32768..65535), otherwise `lui rt, hi16` then `ori rt, rt, lo16` (the `ori` is omitted when `lo16` is 0) |
| `b label`          | `beq $0, $0, label`                                                               |
| `not rd, rs`       | `nor rd, rs, $0`                                                                  |
| `neg rd, rs`       | `sub rd, $0, rs`                                                                  |
| `halt`             | `j <itself>`: the PC stops moving, which the testbench detects as the end of the program |

---

# MainDec Tables

## ALU Operations

The 3-bit `AluOp` produced by the main decoder tells the ALU decoder what to do.

| AluOp$_{2:0}$ | Description                                |
|:-------------:| ------------------------------------------ |
| 0x0           | Addition (`lw`, `sw`, `addi`, `addiu`, `lui`) |
| 0x1           | And (`andi`)                               |
| 0x2           | Subtract (`beq`, `bne`)                    |
| 0x3           | Check Funct (R-type)                       |
| 0x4           | Or (`ori`)                                 |
| 0x5           | Set Less Than (`slti`)                     |
| 0x6           | Set Less Than Unsigned (`sltiu`)           |
| 0x7           | Xor (`xori`)                               |

## ALU Control Signals

| ALU Control$_{3:0}$ | Function                                    |
|:-------------------:|:-------------------------------------------:|
| 0x0                 | $A \land B$                                 |
| 0x1                 | $A \lor B$                                  |
| 0x2                 | $A + B$                                     |
| 0x3                 | $\neg (A \lor B)$ (NOR)                     |
| 0x4                 | $A \land (\neg B)$                          |
| 0x5                 | $A \lor (\neg B)$                           |
| 0x6                 | $A - B$                                     |
| 0x7                 | Set Less Than (SLT, signed)                 |
| 0x8                 | Set Less Than Unsigned (SLTU)               |
| 0x9                 | $A \oplus B$ (XOR)                          |
| 0xA                 | $B \ll shamt$ (SLL)                         |
| 0xB                 | $B \gg shamt$ (SRL, logical)                |
| 0xC                 | $B \gg shamt$ (SRA, arithmetic)             |
| 0xD                 | <mark>Unused</mark>                         |
| 0xE                 | <mark>Unused</mark>                         |
| 0xF                 | <mark>Unused</mark>                         |

The ALU also outputs a `zero` flag (result equal to 0) used by `beq` / `bne`. An unused control value gives an all-ones result.

## Immediate Extension

| ExtOp$_{1:0}$ | Immediate                         | Used by                                      |
|:-------------:| --------------------------------- | -------------------------------------------- |
| 0x0           | sign-extended                     | `addi`, `addiu`, `slti`, `sltiu`, `lw`, `sw` |
| 0x1           | zero-extended                     | `andi`, `ori`, `xori`                        |
| 0x2           | placed in the upper half word     | `lui`                                        |

## Instruction Control Signals

Don't-care values are driven to 0 by the hardware so that no undefined value reaches the datapath in simulation.

| Instruction | OpCode$_{5:0}$ | Reg<br/>Dst | Alu<br/>Src | Mem<br/>Write | Mem<br/>ToReg | Reg<br/>Write | Branch | Bne | Jump | Link | Ext<br/>Op$_{1:0}$ | Alu<br/>Op$_{2:0}$ | ALU<br/>Control$_{3:0}$ |
|:-----------:|:--------------:|:-----------:|:-----------:|:-------------:|:-------------:|:-------------:|:------:|:---:|:----:|:----:|:------------------:|:------------------:|:-----------------------:|
| R-Type      | 0x00           | 1           | 0           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x0                | 0x3                | See R-Type Table        |
| `lw`        | 0x23           | 0           | 1           | 0             | 1             | 1             | 0      | 0   | 0    | 0    | 0x0                | 0x0                | 0x2                     |
| `sw`        | 0x2B           | 0           | 1           | 1             | 0             | 0             | 0      | 0   | 0    | 0    | 0x0                | 0x0                | 0x2                     |
| `addi`      | 0x08           | 0           | 1           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x0                | 0x0                | 0x2                     |
| `addiu`     | 0x09           | 0           | 1           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x0                | 0x0                | 0x2                     |
| `andi`      | 0x0C           | 0           | 1           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x1                | 0x1                | 0x0                     |
| `ori`       | 0x0D           | 0           | 1           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x1                | 0x4                | 0x1                     |
| `xori`      | 0x0E           | 0           | 1           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x1                | 0x7                | 0x9                     |
| `slti`      | 0x0A           | 0           | 1           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x0                | 0x5                | 0x7                     |
| `sltiu`     | 0x0B           | 0           | 1           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x0                | 0x6                | 0x8                     |
| `lui`       | 0x0F           | 0           | 1           | 0             | 0             | 1             | 0      | 0   | 0    | 0    | 0x2                | 0x0                | 0x2                     |
| `beq`       | 0x04           | 0           | 0           | 0             | 0             | 0             | 1      | 0   | 0    | 0    | 0x0                | 0x2                | 0x6                     |
| `bne`       | 0x05           | 0           | 0           | 0             | 0             | 0             | 1      | 1   | 0    | 0    | 0x0                | 0x2                | 0x6                     |
| `j`         | 0x02           | 0           | 0           | 0             | 0             | 0             | 0      | 0   | 1    | 0    | 0x0                | 0x0                | 0x2 (unused)            |
| `jal`       | 0x03           | 0           | 0           | 0             | 0             | 1             | 0      | 0   | 1    | 1    | 0x0                | 0x0                | 0x2 (unused)            |

* Branches: the decoder asserts `Branch` and `Bne`; the core computes `PCSrc = Branch AND (Zero XOR Bne)`, so `beq` is taken when the subtraction gives zero and `bne` when it does not.
* `jal`: `Link` overrides the destination register with `$31` and the written value with `PC+4`.
* `jr` is an R-type instruction recognised from its `funct` field (`0x08`) by the `decoder`: it raises the `jr` signal (next PC taken from `R[rs]`) and cancels `RegWrite`.

## R-Types ALU Control Signals

| R-Type Instruction | Funct$_{5:0}$ | ALU Control$_{3:0}$ |
|:------------------:|:-------------:|:-------------------:|
| `sll`              | 0x00          | 0xA                 |
| `srl`              | 0x02          | 0xB                 |
| `sra`              | 0x03          | 0xC                 |
| `jr`               | 0x08          | - (not an ALU operation) |
| `add`              | 0x20          | 0x2                 |
| `addu`             | 0x21          | 0x2                 |
| `sub`              | 0x22          | 0x6                 |
| `subu`             | 0x23          | 0x6                 |
| `and`              | 0x24          | 0x0                 |
| `or`               | 0x25          | 0x1                 |
| `xor`              | 0x26          | 0x9                 |
| `nor`              | 0x27          | 0x3                 |
| `slt`              | 0x2A          | 0x7                 |
| `sltu`             | 0x2B          | 0x8                 |
