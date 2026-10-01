# Shifts, xor/xori, sltu/sltiu, lui and 32-bit constants (li = lui + ori).
# Results are stored at consecutive words: MEM[4*k].
        li   $t0, 0x12345678        # lui + ori
        li   $t1, -1                # 0xFFFFFFFF
        li   $t2, 0x80000000        # lui only
        sw   $t0, 0($0)             # 0x12345678

        sll  $t3, $t0, 4            # 0x23456780
        sw   $t3, 4($0)
        srl  $t3, $t0, 4            # 0x01234567
        sw   $t3, 8($0)
        sra  $t3, $t2, 4            # sign fill: 0xF8000000
        sw   $t3, 12($0)
        srl  $t3, $t2, 4            # zero fill: 0x08000000
        sw   $t3, 16($0)
        sra  $t3, $t0, 4            # positive value: 0x01234567
        sw   $t3, 20($0)
        sll  $t3, $t1, 31           # 0x80000000
        sw   $t3, 24($0)
        sll  $t3, $t0, 0            # unchanged
        sw   $t3, 28($0)

        xor  $t3, $t0, $t1          # ~0x12345678 = 0xEDCBA987
        sw   $t3, 32($0)
        xor  $t3, $t0, $t0          # 0
        sw   $t3, 36($0)
        xori $t3, $t0, 0xFFFF       # 0x1234A987 (zero-extended immediate)
        sw   $t3, 40($0)

        sltu $t3, $t0, $t2          # 0x12345678 < 0x80000000 unsigned -> 1
        sw   $t3, 44($0)
        slt  $t3, $t0, $t2          # signed: positive < negative -> 0
        sw   $t3, 48($0)
        sltu $t3, $t1, $t0          # 0xFFFFFFFF < 0x12345678 -> 0
        sw   $t3, 52($0)
        sltu $t3, $0, $t1           # 0 < 0xFFFFFFFF -> 1
        sw   $t3, 56($0)
        sltiu $t3, $0, -1           # imm sign-extended to 0xFFFFFFFF: 0 < max -> 1
        sw   $t3, 60($0)
        sltiu $t3, $t1, -1          # 0xFFFFFFFF < 0xFFFFFFFF -> 0
        sw   $t3, 64($0)
        sltiu $t3, $t0, 1           # 0x12345678 < 1 -> 0
        sw   $t3, 68($0)

        lui  $t3, 0xABCD            # 0xABCD0000
        sw   $t3, 72($0)
        lui  $t3, 1                 # 0x00010000
        sw   $t3, 76($0)
        not  $t3, $t0               # 0xEDCBA987
        sw   $t3, 80($0)
        neg  $t3, $t0               # -0x12345678 = 0xEDCBA988
        sw   $t3, 84($0)
        halt

# expect MEM[0]  = 0x12345678
# expect MEM[4]  = 0x23456780
# expect MEM[8]  = 0x01234567
# expect MEM[12] = 0xF8000000
# expect MEM[16] = 0x08000000
# expect MEM[20] = 0x01234567
# expect MEM[24] = 0x80000000
# expect MEM[28] = 0x12345678
# expect MEM[32] = 0xEDCBA987
# expect MEM[36] = 0
# expect MEM[40] = 0x1234A987
# expect MEM[44] = 1
# expect MEM[48] = 0
# expect MEM[52] = 0
# expect MEM[56] = 1
# expect MEM[60] = 1
# expect MEM[64] = 0
# expect MEM[68] = 0
# expect MEM[72] = 0xABCD0000
# expect MEM[76] = 0x00010000
# expect MEM[80] = 0xEDCBA987
# expect MEM[84] = 0xEDCBA988
