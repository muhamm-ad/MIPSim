# beq / bne taken and not taken, forward and backward, and no delay slot:
# the instruction after a taken branch must NOT execute.
        li   $t0, 5
        li   $t1, 5
        li   $s0, 0
        beq  $t0, $t1, b1       # taken
        addi $s0, $s0, 1        # skipped
b1:     bne  $t0, $t1, b2       # not taken
        addi $s0, $s0, 2        # executed
b2:     beq  $t0, $0, b3        # not taken
        addi $s0, $s0, 4        # executed
b3:     bne  $t0, $0, b4        # taken
        addi $s0, $s0, 8        # skipped
b4:     sw   $s0, 0($0)         # 2 + 4 = 6

        # backward branch: sum = 10 + 9 + ... + 1
        li   $t0, 10
        li   $t1, 0
loop:   add  $t1, $t1, $t0
        addi $t0, $t0, -1
        bne  $t0, $0, loop
        sw   $t1, 4($0)         # 55

        # forward exit with an unconditional jump back
        li   $t0, 3
        li   $t2, 0
l2:     beq  $t0, $0, done2
        addi $t2, $t2, 10
        addi $t0, $t0, -1
        j    l2
done2:  sw   $t2, 8($0)         # 30

        # branch comparing negative numbers and a branch on a register pair that differ only in one bit
        li   $t0, -1
        li   $t1, -1
        li   $s1, 0
        bne  $t0, $t1, bad      # equal: not taken
        li   $t1, -2
        beq  $t0, $t1, bad      # different: not taken
        li   $s1, 1
bad:    sw   $s1, 12($0)        # 1
        halt

# expect MEM[0]  = 6
# expect MEM[4]  = 55
# expect MEM[8]  = 30
# expect MEM[12] = 1
