# Every ALU instruction, with positive and negative operands.
# Results are stored at consecutive words: MEM[4*k] for k = 0, 1, 2, ...
        li   $t0, 12            # 0x0000000C
        li   $t1, 10            # 0x0000000A
        li   $t3, -1            # 0xFFFFFFFF

        add  $t2, $t0, $t1      # 22
        sw   $t2, 0($0)
        addu $t2, $t0, $t1      # 22
        sw   $t2, 4($0)
        sub  $t2, $t0, $t1      # 2
        sw   $t2, 8($0)
        subu $t2, $t1, $t0      # -2
        sw   $t2, 12($0)
        and  $t2, $t0, $t1      # 0xC & 0xA = 8
        sw   $t2, 16($0)
        or   $t2, $t0, $t1      # 0xC | 0xA = 14
        sw   $t2, 20($0)
        nor  $t2, $t0, $t1      # ~(0xC | 0xA) = 0xFFFFFFF1 = -15
        sw   $t2, 24($0)

        slt  $t2, $t1, $t0      # 10 < 12 -> 1
        sw   $t2, 28($0)
        slt  $t2, $t0, $t1      # 12 < 10 -> 0
        sw   $t2, 32($0)
        slt  $t2, $t3, $t1      # -1 < 10 -> 1   (signed comparison)
        sw   $t2, 36($0)
        slt  $t2, $t1, $t3      # 10 < -1 -> 0
        sw   $t2, 40($0)
        slt  $t2, $t0, $t0      # 12 < 12 -> 0
        sw   $t2, 44($0)

        addi  $t2, $t0, -20     # 12 - 20 = -8        (sign-extended immediate)
        sw   $t2, 48($0)
        addiu $t2, $t0, 100     # 112
        sw   $t2, 52($0)
        andi $t2, $t3, 0xFF00   # 0xFFFFFFFF & 0x0000FF00 = 0xFF00 (zero-extended immediate)
        sw   $t2, 56($0)
        ori  $t2, $0, 0xFFFF    # 0x0000FFFF (not 0xFFFFFFFF: zero-extended immediate)
        sw   $t2, 60($0)
        ori  $t2, $t0, 3        # 0xC | 0x3 = 15
        sw   $t2, 64($0)
        slti $t2, $t3, 0        # -1 < 0  -> 1
        sw   $t2, 68($0)
        slti $t2, $t0, 12       # 12 < 12 -> 0
        sw   $t2, 72($0)
        slti $t2, $t0, 13       # 12 < 13 -> 1
        sw   $t2, 76($0)

        addi $0, $0, 5          # writes to $0 are ignored
        sw   $0, 80($0)         # 0
        move $t4, $t0           # 12
        sw   $t4, 84($0)

        .word 0xFFFFFFFF        # illegal opcode: must act as a no-op (no write, no store)
        sw   $t0, 88($0)        # 12
        halt

# expect MEM[0]  = 22
# expect MEM[4]  = 22
# expect MEM[8]  = 2
# expect MEM[12] = -2
# expect MEM[16] = 8
# expect MEM[20] = 14
# expect MEM[24] = -15
# expect MEM[28] = 1
# expect MEM[32] = 0
# expect MEM[36] = 1
# expect MEM[40] = 0
# expect MEM[44] = 0
# expect MEM[48] = -8
# expect MEM[52] = 112
# expect MEM[56] = 0xFF00
# expect MEM[60] = 0xFFFF
# expect MEM[64] = 15
# expect MEM[68] = 1
# expect MEM[72] = 0
# expect MEM[76] = 1
# expect MEM[80] = 0
# expect MEM[84] = 12
# expect MEM[88] = 12
