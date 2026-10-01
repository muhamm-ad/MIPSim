# j: forward over instructions, a chain of jumps, and a backward jump in a loop.
        li   $s0, 1
        j    skip1
        li   $s0, 99            # skipped
skip1:  j    skip2
        li   $s0, 98            # skipped
        li   $s0, 97            # skipped
skip2:  sw   $s0, 0($0)         # 1

        li   $t0, 0
back:   addi $t0, $t0, 1
        li   $t1, 4
        beq  $t0, $t1, out
        j    back
out:    sw   $t0, 4($0)         # 4
        halt

# expect MEM[0] = 1
# expect MEM[4] = 4
