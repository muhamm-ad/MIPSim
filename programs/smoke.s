# Smoke test: the demo program of imem.vhd, with its results stored to memory.
        addi $v0, $0, 5         # $v0 = 5
        addi $v1, $0, 12        # $v1 = 12
        addi $a3, $v1, -9       # $a3 = 12 - 9 = 3
        or   $a0, $a3, $v0      # $a0 = 3 | 5  = 7
        and  $a1, $v1, $a0      # $a1 = 12 & 7 = 4
        add  $a1, $a1, $a0      # $a1 = 4 + 7  = 11
        sw   $a1, 0($0)
        sw   $a0, 4($0)
        halt

# expect MEM[0x0] = 11
# expect MEM[0x4] = 7
