# Load / store: base registers, offsets (positive and negative), overwrite,
# and a load immediately followed by a use of the loaded value.
        li   $s0, 64            # base byte address (word 16)
        li   $t1, 111
        sw   $t1, 0($s0)        # MEM[64] = 111
        li   $t1, 222
        sw   $t1, 4($s0)        # MEM[68] = 222
        lw   $t2, 0($s0)        # 111
        lw   $t3, 4($s0)        # 222
        add  $t4, $t2, $t3      # 333
        sw   $t4, 8($s0)        # MEM[72] = 333

        addi $s1, $s0, 8        # $s1 = 72
        lw   $t5, -8($s1)       # negative offset: MEM[64] = 111
        sw   $t5, 12($s0)       # MEM[76] = 111

        sw   $t4, 0($s0)        # overwrite MEM[64] = 333

        lw   $t6, 8($s0)        # 333
        addi $t6, $t6, 1        # use the loaded value right away
        sw   $t6, 16($s0)       # MEM[80] = 334

        lw   $t7, 0($0)         # never written: the memory starts cleared
        sw   $t7, 20($s0)       # MEM[84] = 0
        halt

# expect MEM[64] = 333
# expect MEM[68] = 222
# expect MEM[72] = 333
# expect MEM[76] = 111
# expect MEM[80] = 334
# expect MEM[84] = 0
