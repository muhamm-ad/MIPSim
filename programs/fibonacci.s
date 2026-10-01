# First 12 Fibonacci numbers: MEM[4*n] = F(n).
        li   $t0, 0             # F(n-2)
        li   $t1, 1             # F(n-1)
        li   $s0, 0             # byte address of the next word
        li   $s1, 48            # stop after 12 words
        sw   $t0, 0($s0)        # F(0)
        addi $s0, $s0, 4
        sw   $t1, 0($s0)        # F(1)
        addi $s0, $s0, 4
fib:    beq  $s0, $s1, done
        add  $t2, $t0, $t1
        sw   $t2, 0($s0)
        move $t0, $t1
        move $t1, $t2
        addi $s0, $s0, 4
        j    fib
done:   halt

# expect MEM[0]  = 0
# expect MEM[4]  = 1
# expect MEM[8]  = 1
# expect MEM[12] = 2
# expect MEM[16] = 3
# expect MEM[20] = 5
# expect MEM[24] = 8
# expect MEM[28] = 13
# expect MEM[32] = 21
# expect MEM[36] = 34
# expect MEM[40] = 55
# expect MEM[44] = 89
