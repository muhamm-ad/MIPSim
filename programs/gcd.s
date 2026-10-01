# Greatest common divisor by repeated subtraction (slt, beq, bne, sub, j).
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

        li   $a0, 1071
        li   $a1, 462
g2:     beq  $a0, $a1, d2
        slt  $t0, $a1, $a0
        bne  $t0, $0, a2gt
        sub  $a1, $a1, $a0
        j    g2
a2gt:   sub  $a0, $a0, $a1
        j    g2
d2:     sw   $a0, 4($0)         # gcd(1071, 462) = 21
        halt

# expect MEM[0] = 6
# expect MEM[4] = 21
