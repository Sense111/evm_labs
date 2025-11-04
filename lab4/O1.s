f:
        stp     x29, x30, [sp, -32]!; сам стек уменьшен, так как нет нужды теперь хранить в нём x. Также используются stp вместо str и ldp вместо ldr
        mov     x29, sp
        stp     d14, d15, [sp, 16]; в сравнении с O0 не сохраняет x в стек, вместо этого держит его в регистре
        fmov    d14, d0
        bl      exp
        fmov    d15, d0
        fmov    d0, d14
        bl      sin
        fmul    d0, d15, d0
        ldp     d14, d15, [sp, 16]
        ldp     x29, x30, [sp], 32
        ret
.LC0:
        .string "%d"
.LC1:
        .string "a = %.10f, b = %.10f, h = %.10f\n"
.LC2:
        .base64 "0J/RgNC40LHQu9C40LbRkdC90L3QvtC1INC30L3QsNGH0LXQvdC40LUg0LjQvdGC0LXQs9GA0LDQu9CwOiAlLjEwZgoA"
.LC3:
        .string "Time taken: %lf sec.\n"
main:
        stp     x29, x30, [sp, -128]!
        mov     x29, sp
        add     x1, sp, 112; теперь не sp+96, а sp+112, так как компилятор переупорядочил размещение переменных в стеке, чтобы лучше использовать выравнивание
        mov     w0, 4
        bl      clock_gettime
        add     x1, sp, 92
        adrp    x0, .LC0
        add     x0, x0, :lo12:.LC0
        bl      __isoc23_scanf
        mov     w1, w0
        mov     w0, 1
        cmp     w1, w0
        bne     .L3
        stp     x19, x20, [sp, 16]
        stp     d12, d13, [sp, 48]; также вместо str stp используется
        stp     d14, d15, [sp, 64]
        ldr     w20, [sp, 92]; N-> w20(int)
        scvtf   d31, w20; N-> double
        adrp    x0, .LC4
        ldr     d14, [x0, #:lo12:.LC4]; M_PI -> d14
        fdiv    d14, d14, d31; h= M_PI / N ->d14 Здесь идёт упрощение. а=0 пропускается и сразу без него считается
        cmp     w20, 0; Компилятор добавил защиту, если окажется, что N<=0, то интеграл станет нулём сразу
        ble     .L8
        stp     d10, d11, [sp, 32]
        mov     w19, 0
        movi    d13, #0
        fmov    d12, d13
        fmov    d11, 5.0e-1; умножение на 0,5 более дешёвая операция, чем деление на 2
.L6:
        scvtf   d0, w19
        fmul    d0, d0, d14
        add     w19, w19, 1
        scvtf   d10, w19
        fmul    d10, d10, d14
        fadd    d10, d10, d12
        fadd    d0, d0, d12
        bl      f; опять же используются чисто регистры без обращений к памяти
        fmov    d15, d0
        fmov    d0, d10
        bl      f
        fadd    d15, d15, d0
        fmul    d15, d15, d11
        fadd    d13, d13, d15
        cmp     w20, w19; k!=N и инкремент делается раньше
        bne     .L6
        ldp     d10, d11, [sp, 32]
.L5:
        fmov    d2, d14
        adrp    x0, .LC4
        ldr     d1, [x0, #:lo12:.LC4]
        movi    d0, #0 ; a=0.0 не хранится в памяти, а сразу загружается как #0
        adrp    x0, .LC1
        add     x0, x0, :lo12:.LC1
        bl      printf
        fmul    d0, d14, d13
        adrp    x0, .LC2
        add     x0, x0, :lo12:.LC2
        bl      printf
        add     x1, sp, 96
        mov     w0, 4
        bl      clock_gettime
        ldr     x0, [sp, 104]
        ldr     x1, [sp, 120]
        sub     x0, x0, x1
        fmov    d31, x0
        scvtf   d31, d31
        adrp    x0, .LC5
        ldr     d30, [x0, #:lo12:.LC5]
        fmul    d31, d31, d30
        ldr     x0, [sp, 96]
        ldr     x1, [sp, 112]
        sub     x0, x0, x1
        fmov    d0, x0
        scvtf   d0, d0
        fadd    d0, d31, d0
        adrp    x0, .LC3
        add     x0, x0, :lo12:.LC3
        bl      printf
        mov     w0, 0
        ldp     x19, x20, [sp, 16]
        ldp     d12, d13, [sp, 48]
        ldp     d14, d15, [sp, 64]
.L3:
        ldp     x29, x30, [sp], 128
        ret
.L8:
        movi    d13, #0
        b       .L5
.LC4:
        .word   1413754136
        .word   1074340347
.LC5:
        .word   -400107883
        .word   1041313291
