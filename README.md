# MIPSim: MIPS Processor VHDL Simulation

MIPSim is a MIPS (Microprocessor without Interlocked Pipeline Stages) processor simulation project designed in VHDL (VHSIC Hardware Description Language). This project aims to provide a detailed implementation of the MIPS processor.

## Features

* Complete simulation of a 32-bit, single-cycle MIPS processor running programs loaded from a file.
* 28 MIPS instructions covering arithmetic, logic, shifts, comparisons, loads/stores, conditional branches, jumps and function calls (`jal` / `jr`). See [`Docs/Supported_Instruction.md`](Docs/Supported_Instruction.md).
* Modular architecture for easy understanding and extension.
* Self-checking testbenches for every module, and a system-level test bench that runs real programs (GCD, Fibonacci, bubble sort, recursive factorial, ...).
* A small assembler (`tools/asm.py`) to write programs in MIPS assembly instead of hexadecimal.
* Continuous integration on every push and pull request.

## Prerequisites

* [GHDL](https://github.com/ghdl/ghdl) with VHDL-2008 support (developed and tested with GHDL 4.1, `--std=08`), or another VHDL-2008 simulator.
* GNU `make`.
* Python 3 (only to assemble programs, to run the assembler tests and for `make sim`; the assembled programs are committed, so `make check` and `make test` do not need it).

## Quick start

```sh
make check                    # analyse and elaborate every module of hdl_export/
make test                     # unit testbenches + every program of programs/
make test-tools               # unit tests of the assembler
make sim PROG=programs/gcd    # assemble and run one program, printing every store
make wave T=tb_alu            # run one testbench and dump build/tb_alu.ghw (for GTKWave)
```

`make sim PROG=programs/gcd` prints each write to the data memory, then the verdict of the testbench:

```
tb/tb_mips.vhd:96:25:@235ns:(report note): store MEM[00000000] = 00000006 (6) at pc=00000024
tb/tb_mips.vhd:96:25:@825ns:(report note): store MEM[00000004] = 00000015 (21) at pc=0000004C
tb/tb_mips.vhd:144:9:@845ns:(report note): tb_mips[programs/gcd.hex]: PASS (85 cycles, 2 stores, 2 expectations)
```

## Repository layout

| Path                         | Content                                                                 |
| ---------------------------- | ----------------------------------------------------------------------- |
| `hdl_export/`                | The VHDL design (one entity per file)                                   |
| `tb/`                        | Self-checking testbenches (`tb_<module>.vhd`) and `tb/fixtures/`        |
| `programs/`                  | Test programs: assembly source (`.s`), generated `.hex` and `.expect`   |
| `tools/`                     | The assembler `asm.py` and its unit tests                               |
| `Docs/`                      | Instruction set and control tables, datapath diagram (`mipsim.drawio`), MIPS Green Sheet |
| `Makefile`                   | Build and test entry points                                             |
| `.github/workflows/ci.yml`   | Continuous integration                                                  |

## Architecture

```
top                         processor + memories (exposes pc and the store interface for testbenches)
├── mips                    core: connects the decoder to the datapath, resolves branches
│   ├── decoder             control unit
│   │   ├── maindec         opcode -> control signals
│   │   └── aludec          (ALUop, funct) -> 4-bit ALU control
│   └── datapath            PC, next-PC logic, register file, immediate extension, ALU, write-back
│       ├── flopr           program counter register (asynchronous reset)
│       ├── adder           PC+4 and branch target
│       ├── mux             all the selections (generic width and number of inputs)
│       ├── reg             32 x 32-bit register file, 2 read ports, $0 hard-wired to zero
│       ├── signext         16 -> 32-bit sign extension
│       └── alu             and/or/xor/nor, add/sub, signed and unsigned compare, shifts
├── imem                    instruction memory, program loaded from a hex file
└── dmem                    data memory, word access with byte addresses
```

[`Docs/mipsim.drawio`](Docs/mipsim.drawio) draws the original datapath (register file, ALU, memories, R-type / `lw` / `sw` / `addi` data flow); it predates the next-PC logic (branch, jump, `jr`), the `jal` link path and the immediate-extension mux, which are documented in the header of `hdl_export/datapath.vhd`. The control signals of every instruction and the ALU encodings are tabulated in [`Docs/Supported_Instruction.md`](Docs/Supported_Instruction.md).

`top` has three generics: `IMEM_ADDR_SIZE` (instruction memory of `2**IMEM_ADDR_SIZE` words, 6 by default), `DMEM_SIZE` (data memory size in words, 64 by default) and `PROGRAM` (path of the program file; empty selects a small built-in demo program).

## Writing and running a program

Programs are written in MIPS assembly. For example `programs/gcd.s`:

```asm
        li   $a0, 48
        li   $a1, 18
g1:     beq  $a0, $a1, d1
        slt  $t0, $a1, $a0      # b < a ?
        bne  $t0, $0, a1gt
        sub  $a1, $a1, $a0      # b -= a
        j    g1
a1gt:   sub  $a0, $a0, $a1      # a -= b
        j    g1
d1:     sw   $a0, 0($0)         # gcd(48, 18) = 6
        halt

# expect MEM[0] = 6
```

* `halt` is a pseudo-instruction (`j` to itself): the testbench stops the simulation when the program counter stops moving.
* `# expect MEM[<byte address>] = <value>` comments state what the data memory must contain once the program has halted. The testbench fails if a value differs, if the program does not halt, or if it stores outside the data memory.
* `python3 tools/asm.py prog.s -l` assembles a program and prints a listing; `make programs` re-assembles everything in `programs/`. The generated `.hex` / `.expect` files are committed and CI checks that they are up to date.
* Drop a new `programs/<name>.s` in the directory, run `make programs`, and `make test` will run it.

The hex program format read by `imem` is one 32-bit instruction per line (exactly 8 hexadecimal digits); anything after the digits is ignored, and blank lines and lines starting with `#`, `//` or `--` are comments.

## Testing

* **Unit testbenches** in `tb/` check each module on directed corner cases and, where useful, pseudo-random or exhaustive vectors (for instance the ALU against a reference model, the sign extender over all 65 536 inputs, the 8-bit adder exhaustively). Each one asserts at severity `error`, so `make test` stops at the first mismatch and prints what was expected and what was produced.
* **`tb_datapath`** drives the datapath with hand-encoded instructions and the control word the decoder would produce.
* **`tb_mips`** runs complete programs on the whole system and compares the final data memory with the `.expect` files.
* **`tools/test_asm.py`** tests the assembler against encodings computed by hand from the Green Sheet.

## Contributing

Contributions are welcome, whether they are extensions, bug fixes, or improved documentation.

The project uses a git-flow style workflow:

* `master` holds releases, `develop` is the integration branch.
* Work happens on short-lived branches created from `develop` (`feature/...`, `fix/...`, `docs/...`) and comes back through a pull request.
* A pull request is ready when CI is green, i.e. `make test-tools`, `make programs` (no diff), `make check` and `make test` all pass. Please add a testbench or a program with the feature, and run `make test` from a clean tree (`make clean`) before pushing.

## Roadmap

Not implemented yet: byte and half-word loads/stores, `mult` / `div` and `hi` / `lo`, variable shifts, `jalr`, the remaining conditional branches (`bltz`, `bgez`, `blez`, `bgtz`), exceptions (an undefined `funct` currently writes all ones to `rd` instead of trapping), and a pipelined version of the core.

## License

This project is licensed under the MIT License. Please see the `LICENSE` file for more details.

## Authors

* [muhamm-ad · GitHub](https://github.com/muhamm-ad)
