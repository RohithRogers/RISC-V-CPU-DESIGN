.section .text
.globl _start
_start:
    addi x1, x0, 10
    addi x2, x0, 3

    add  x3, x1, x2     # 13
    sub  x4, x1, x2     # 7
    and  x5, x1, x2     # 2
    or   x6, x1, x2     # 11
    xor  x7, x1, x2     # 9
    sll  x8, x2, x2     # 3 << 3 = 24
    srl  x9, x8, x2     # 24 >> 3 = 3
    slt  x10, x2, x1    # 1

    nop
    nop
    nop
