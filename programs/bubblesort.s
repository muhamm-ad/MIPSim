# Bubble sort of 8 words stored at byte addresses 0..28.
# Initial array: 5 2 9 1 7 3 8 4      sorted: 1 2 3 4 5 7 8 9
        li   $t0, 5
        sw   $t0, 0($0)
        li   $t0, 2
        sw   $t0, 4($0)
        li   $t0, 9
        sw   $t0, 8($0)
        li   $t0, 1
        sw   $t0, 12($0)
        li   $t0, 7
        sw   $t0, 16($0)
        li   $t0, 3
        sw   $t0, 20($0)
        li   $t0, 8
        sw   $t0, 24($0)
        li   $t0, 4
        sw   $t0, 28($0)

        li   $s0, 28            # byte offset of the last element: stop the inner loop here
outer:  li   $s1, 0             # swapped = 0
        li   $t0, 0             # i = 0 (byte offset)
inner:  beq  $t0, $s0, endin
        lw   $t1, 0($t0)        # a[i]
        lw   $t2, 4($t0)        # a[i+1]
        slt  $t3, $t2, $t1      # a[i+1] < a[i] ?
        beq  $t3, $0, noswap
        sw   $t2, 0($t0)        # swap
        sw   $t1, 4($t0)
        li   $s1, 1
noswap: addi $t0, $t0, 4
        j    inner
endin:  bne  $s1, $0, outer     # another pass if anything was swapped
        halt

# expect MEM[0]  = 1
# expect MEM[4]  = 2
# expect MEM[8]  = 3
# expect MEM[12] = 4
# expect MEM[16] = 5
# expect MEM[20] = 7
# expect MEM[24] = 8
# expect MEM[28] = 9
