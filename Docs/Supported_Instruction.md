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

| Name                   | Mnemonic | Format | Funct | Operation                   |
|:----------------------:|:--------:|:------:|:-----:|:---------------------------:|
| Add                    | `add`    | R      | 0x20  | R[rd] = R[rs] + R[rt]       |
| Add Unsigned           | `addu`   | R      | 0x21  | R[rd] = R[rs] + R[rt]       |
| Add Immediate          | `addi`   | I      | 0x08  | R[rt] = R[rs] + SignExtImm  |
| Add Immediate Unsigned | `addiu`  | I      | 0x09  | R[rt] = R[rs] + SignExtImm  |
| And                    | `and`    | R      | 0x24  | R[rd] = R[rs] & R[rt]       |
| And Immediate          | `andi`   | I      | 0x0C  | R[rt] = R[rs] & ZeroExtImm  |
| Or                     | `or`     | R      | 0x25  | R[rd] = R[rs] \| R[rt]      |
| Or Immediate           | `ori`    | I      | 0x0D  | R[rt] = R[rs] \| ZeroExtImm |
| Nor                    | `nor`    | R      | 0x27  | R[rd] = ~ (R[rs] \| R[rt])  |
| Subtract               | `sub`    | R      | 0x22  | R[rd] = R[rs] - R[rt]       |
| Subtract Unsigned      | `subu`   | R      | 0x23  | R[rd] = R[rs] - R[rt]       |
| Load Word              | `lw`     | I      | 0x23  | R[rt] = M[R[rs]+SignExtImm] |
| Store Word             | `sw`     | I      | 0x2B  | M[R[rs]+SignExtImm] = R[rt] |

---

# MainDec Tables

## ALU Operations

| AluOp$_{1:0}$ | Description |
|:-------------:| ----------- |
| 0x0           | Addition    |
| 0x2           | Subtract    |
| 0x3           | Check Funct |
| 0x4           | Not Used    |

## ALU Control Signals

| ALU Control$_{3:0}$ | Function            |
|:-------------------:|:-------------------:|
| 0x0                 | $A \land B$         |
| 0x1                 | $A \lor B$          |
| 0x2                 | $A + B$             |
| 0x3                 | <mark>Unused</mark> |
| 0x4                 | $A \land (\neg B)$  |
| 0x5                 | $A \lor (\neg B)$   |
| 0x6                 | $A - B$             |
| 0x7                 | Set Less Than (SLT) |
| 0x8                 | <mark>Unused</mark> |
| 0x9                 | <mark>Unused</mark> |
| 0xA                 | <mark>Unused</mark> |
| 0xB                 | <mark>Unused</mark> |
| 0xC                 | <mark>Unused</mark> |
| 0xD                 | <mark>Unused</mark> |
| 0xE                 | <mark>Unused</mark> |
| 0xF                 | <mark>Unused</mark> |

## Instruction Control Signals

| Instruction | OpCode$_{5:0}$ | Reg<br/>Dst | Alu<br/>Src | Mem<br/>Write | Mem<br/>ToReg | Reg<br/>Write | Alu<br/>Op$_{1:0}$ | ALU<br/>Control$_{3:0}$ |
|:-----------:|:--------------:|:-----------:|:-----------:|:-------------:|:-------------:|:-------------:|:------------------:|:-----------------------:|
| R-Type      | 0x00           | 1           | 0           | 0             | 0             | 1             | 0x3                | See R-Type Table        |
| `lw`        | 0x23           | 0           | 1           | 0             | 1             | 1             | 0x0                | 0x2                     |
| `sw`        | 0x2B           | -           | 1           | 1             | -             | 0             | 0x0                | 0x2                     |
| `addi`      | 0x08           | 0           | 1           | 0             | 0             | 1             | 0x0                | 0x2                     |
| `andi`      | 0x0C           | 0           | 1           | 0             | 0             | 1             |                    |                         |
| `ori`       | 0x0D           | 0           | 1           | 0             | 0             | 1             |                    |                         |
| `addiu`     | 0x09           | 0           | 1           | 0             | 0             | 1             |                    |                         |

## R-Types ALU Control Signals

| R-Type Instruction | Funct$_{5:0}$ | ALU Control$_{3:0}$ |
|:------------------:|:-------------:|:-------------------:|
| `add`              | 0x20          | 0x2                 |
| `addu`             | 0x21          |                     |
| `and`              | 0x24          | 0x0                 |
| `or`               | 0x25          | 0x1                 |
| `nor`              | 0x27          |                     |
| `sub`              | 0x22          | 0x6                 |
| `subu`             | 0x23          |                     |
