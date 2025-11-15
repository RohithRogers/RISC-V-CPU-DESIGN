    .section .text
    .globl _start

_start:
    # x10 = sum = 0
    addi x10, x0, 0

    # x11 = i = 1
    addi x11, x0, 1

    # x12 = limit = 11 (loop runs while i < 11)
    addi x12, x0, 11

loop:
    add x10, x10, x11     # sum += i
    addi x11, x11, 1      # i++
    blt x11, x12, loop    # if (i < 11) loop

    # End program with NOPs
    nop
    nop
    nop

