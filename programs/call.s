# Function calls: jal / jr, a stack in data memory, recursion and nested calls.
        li   $sp, 252               # the stack grows down from the top of the 256-byte data memory

        li   $a0, 6
        jal  fact
        sw   $v0, 0($0)             # 6! = 720
        li   $a0, 5
        jal  fact
        sw   $v0, 4($0)             # 5! = 120
        li   $a0, 0
        jal  fact
        sw   $v0, 8($0)             # 0! = 1

        li   $a0, 10
        jal  twice_plus_one         # nested call: (10 * 2) + 1
        sw   $v0, 12($0)            # 21
        sw   $sp, 16($0)            # every call restored the stack pointer: 252
        halt

# fact(n): recursive, $a0 = n, result in $v0. Saves $ra and n on the stack.
fact:   addi $sp, $sp, -8
        sw   $ra, 4($sp)
        sw   $a0, 0($sp)
        slti $t0, $a0, 2            # n < 2 ?
        beq  $t0, $0, recurse
        li   $v0, 1                 # base case: 0! = 1! = 1
        addi $sp, $sp, 8
        jr   $ra
recurse:
        addi $a0, $a0, -1
        jal  fact                   # $v0 = (n-1)!
        lw   $a0, 0($sp)            # restore n
        lw   $ra, 4($sp)            # restore the return address
        addi $sp, $sp, 8
        move $a1, $v0
        li   $v0, 0                 # $v0 = n * (n-1)!, by repeated addition
mloop:  beq  $a0, $0, mdone
        add  $v0, $v0, $a1
        addi $a0, $a0, -1
        j    mloop
mdone:  jr   $ra

# twice_plus_one(x) = twice(x) + 1: a non-leaf function calling a leaf function.
twice_plus_one:
        addi $sp, $sp, -4
        sw   $ra, 0($sp)
        jal  twice
        addi $v0, $v0, 1
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
twice:  add  $v0, $a0, $a0
        jr   $ra

# expect MEM[0]  = 720
# expect MEM[4]  = 120
# expect MEM[8]  = 1
# expect MEM[12] = 21
# expect MEM[16] = 252
