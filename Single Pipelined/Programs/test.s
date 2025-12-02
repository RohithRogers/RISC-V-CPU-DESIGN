    .section .text
    .globl _start

_start:
    # Load array address
    lui  x5, %hi(array)
    addi x5, x5, %lo(array)

    addi x6, x0, 5          # element count
    addi x10, x0, 0         # sum

loop:
    beq  x6, x0, done

    lw   x7, 0(x5)
    add  x10, x10, x7

    addi x5, x5, 4
    addi x6, x6, -1

    jal  x0, loop

done:
    jal  x0, done

    .section .data
    .align 4
array:
    .word 10,20,30,40,50
