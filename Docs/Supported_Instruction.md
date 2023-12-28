# Supported Instruction



### BASIC INSTRUCTION FORMATS

![](/home/muham-ad/.var/app/com.github.marktext.marktext/config/marktext/images/2023-12-27-00-15-36-image.png)

<br>

### SUPPORTED INSTRUCTION SET

| NAME                   | MNEMONIC | FORMAT | OPCODE (binary) | FUNCT (binary) | OPERATION                   |
| ---------------------- | -------- | ------ | --------------- | -------------- | --------------------------- |
| Add                    | `add`    | R      | 000000          | 100000         | R[rd] = R[rs] + R[rt]       |
| Add Immediate          | `addi`   | I      | 001000          | NA             | R[rt] = R[rs] + SignExtImm  |
| Add Immediate Unsigned | `addiu`  | I      | 001001          | NA             | R[rt] = R[rs] + SignExtImm  |
| Add Unsigned           | `addu`   | R      | 000000          | 100001         | R[rd] = R[rs] + R[rt]       |
| And                    | `and`    | R      | 000000          | 100100         | R[rd] = R[rs] & R[rt]       |
| And Immediate          | `andi`   | I      | 001100          | NA             | R[rt] = R[rs] & ZeroExtImm  |
| Load Word              | `lw`     | I      | 100011          | NA             | R[rt] = M[R[rs]+SignExtImm] |
| Nor                    | `nor`    | R      | 000000          | 100111         | R[rd] = ~ (R[rs] \| R[rt])  |
| Or                     | `or`     | R      | 000000          | 100101         | R[rd] = R[rs] \| R[rt]      |
| Or Immediate           | `ori`    | I      | 001101          | NA             | R[rt] = R[rs] \| ZeroExtImm |
| Subtract               | `sub`    | R      | 000000          | 100010         | R[rd] = R[rs] - R[rt]       |
| Subtract Unsigned      | `subu`   | R      | 000000          | 100011         | R[rd] = R[rs] - R[rt]       |
| Store Word             | `sw`     | I      | 101011          | NA             | M[R[rs]+SignExtImm] = R[rt] |
