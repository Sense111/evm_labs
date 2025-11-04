f:
        stp     x29, x30, [sp, -48]! ; stp - сохранить 2 регистра в память, где x29 - указатель фрейма, x30 - адрес возврата, a sp -48 означает, что выделяется 48 байт 
        mov     x29, sp ; копируем текущее значение sp в x29 - указатель на начало стекового фрейма этой функции 
        str     d15, [sp, 16]  ; сохранить регистр в память, на 16 байт от sp
        str     d0, [sp, 40] ; сохраняем х на стеке по смещению 40 от sp, чтобы использовать его потом дважды
        ldr     d0, [sp, 40] ; загрузить из памяти в регистр, чтобы передать x в exp(x)
        bl      exp 
        fmov    d15, d0 ; после выполнения exp в предыдущем шаге результат сохранился в d0, сохраняем результат из d0 в  d15 
        ldr     d0, [sp, 40] ; аналогично как и для exp, но теперь для sin
        bl      sin 
        fmov    d31, d0 
        fmul    d31, d15, d31 ; перемножили sin и exp
        fmov    d0, d31 ; скопировали результат из d31 в d0, так как результат вывода функции должен быть в d0
        ldr     d15, [sp, 16] 
        ldp     x29, x30, [sp], 48 ; ldr и ldp возращают изначальное состояние функции
        ret ; выводим результат, который выведется по адресу из x30
.LC0:
        .string "%d"
.LC1:
        .string "a = %.10f, b = %.10f, h = %.10f\n"
.LC2:
        .base64 "0J/RgNC40LHQu9C40LbRkdC90L3QvtC1INC30L3QsNGH0LXQvdC40LUg0LjQvdGC0LXQs9GA0LDQu9CwOiAlLjEwZgoA"
.LC3:
        .string "Time taken: %lf sec.\n"
main:
        stp     x29, x30, [sp, -128]! ; всё также, как в f, но выделяется 128 байт
        mov     x29, sp 
        str     d15, [sp, 16]
        add     x0, sp, 56 ; записывает в x0 адрес, по которому хранится структура timespec
        mov     x1, x0
        mov     w0, 4 ; записали в младшие 32 бита
        bl      clock_gettime
        str     xzr, [sp, 104] ; xzr - нулевой регистр, а=0.0
        adrp    x0, .LC4
        ldr     d31, [x0, #:lo12:.LC4]
        str     d31, [sp, 96]
        add     x0, sp, 36
        mov     x1, x0
        adrp    x0, .LC0
        add     x0, x0, :lo12:.LC0
        bl      __isoc23_scanf
        cmp     w0, 1
        beq     .L4 ; Если scanf вернул не 1, то выход с кодом 1, если вернул 1, то переходим в L4 (Вычисляем дальше h = (b-a)/N)
        mov     w0, 1
        b       .L8
.L4:
        ldr     d30, [sp, 96] ; b
        ldr     d31, [sp, 104] ; a
        fsub    d30, d30, d31 ; d30 = b-a
        ldr     w0, [sp, 36]; N
        scvtf   d31, w0; convert signed integer to float: d31= double(N)
        fdiv    d31, d30, d31; d31= (b-a)/N
        str     d31, [sp, 88]; сохраняем h
        str     xzr, [sp, 120]; Подготовка цикла. integral = 0.0 (double)
        str     wzr, [sp, 116]; k=0 (int) wzr - 32x битный ноль
        b       .L6 ; переход к проверке условия цикла 
.L7:
        ldr     w0, [sp, 116]; k
        scvtf   d30, w0; k-> double 
        ldr     d31, [sp, 88]; h
        fmul    d31, d30, d31; k*h
        ldr     d30, [sp, 104];a = 0.0
        fadd    d31, d30, d31;x_k=a+k*h
        str     d31, [sp, 80]; сохраняем x_k
        ldr     w0, [sp, 116]; k
        add     w0, w0, 1; k+1
        scvtf   d30, w0; -> double
        ldr     d31, [sp, 88]; h
        fmul    d31, d30, d31; (k+1)*h
        ldr     d30, [sp, 104]; a
        fadd    d31, d30, d31;x_(k+1)
        str     d31, [sp, 72]; сохраняем x_(k+1)
        ldr     d0, [sp, 80]; x_k
        bl      f
        fmov    d15, d0
        ldr     d0, [sp, 72]; x_(k+1)
        bl      f
        fmov    d31, d0
        fadd    d30, d15, d31; f(x_k)+f(x_k)
        fmov    d31, 2.0e+0; число 2.0
        fdiv    d31, d30, d31; деление на 2.0
        ldr     d30, [sp, 120]; текущий интеграл
        fadd    d31, d30, d31; интеграл += среднее
        str     d31, [sp, 120]; сохраняем обновлённое значение интеграла
        ldr     w0, [sp, 116]; k
        add     w0, w0, 1; k++
        str     w0, [sp, 116]; сохраняем k
.L6:
        ldr     w0, [sp, 36]; N
        ldr     w1, [sp, 116]; k
        cmp     w1, w0
        blt     .L7; if (k<N) переходим в L7 (в тело цикла)
        ldr     d30, [sp, 120]; интеграл
        ldr     d31, [sp, 88]; h
        fmul    d31, d30, d31; integral *h 
        str     d31, [sp, 120]
        ldr     d2, [sp, 88]; h
        ldr     d1, [sp, 96]; b
        ldr     d0, [sp, 104]; a
        adrp    x0, .LC1
        add     x0, x0, :lo12:.LC1
        bl      printf ; вывод результата
        ldr     d0, [sp, 120]
        adrp    x0, .LC2
        add     x0, x0, :lo12:.LC2
        bl      printf
        add     x0, sp, 40
        mov     x1, x0
        mov     w0, 4
        bl      clock_gettime ; замер времени
        ldr     x1, [sp, 40]; end.tv_sec
        ldr     x0, [sp, 56]; start.tv_sec
        sub     x0, x1, x0; разность времени(сек)
        fmov    d31, x0; -> double
        scvtf   d30, d31; снова конвертируем, хотя уже double
        ldr     x1, [sp, 48]; end.tv_nsec
        ldr     x0, [sp, 64]; start.tv_nsec
        sub     x0, x1, x0; разность нс
        fmov    d31, x0
        scvtf   d31, d31
        adrp    x0, .LC5
        ldr     d29, [x0, #:lo12:.LC5]
        fmul    d31, d31, d29; конвертация нс в с
        fadd    d31, d30, d31; total = сек + сек
        fmov    d0, d31
        adrp    x0, .LC3
        add     x0, x0, :lo12:.LC3
        bl      printf
        mov     w0, 0; return 0
.L8:
        ldr     d15, [sp, 16] ; восстановить первоначальное состояние main
        ldp     x29, x30, [sp], 128
        ret
.LC4:
        .word   1413754136
        .word   1074340347
.LC5:
        .word   -400107883
        .word   1041313291
