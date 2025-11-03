f:
        sub     rsp, 24             ; Выделяем 24 байта (для выравнивания + временного хранения)
        movsd   QWORD PTR [rsp], xmm0   ; Сохраняем x (аргумент в xmm0) в стеке
        call    exp                 ; вызываем exp(x) → результат в xmm0
        movsd   QWORD PTR [rsp+8], xmm0 ; сохраняем exp(x)
        movsd   xmm0, QWORD PTR [rsp]   ; загружаем x обратно в xmm0
        call    sin                 ; sin(x) → xmm0
        mulsd   xmm0, QWORD PTR [rsp+8] ; xmm0 = sin(x) * exp(x)
        add     rsp, 24             ; восстанавливаем стек
        ret
.LC1:   .string "%d"
.LC4:   .string "a = %.10f, b = %.10f, h = %.10f\n"
.LC5:   .base64 "..."  ; "Приближённое значение интеграла: %.10f\n"
.LC7:   .string "Time taken: %lf sec.\n"
.LC2:   ; M_PI ≈ 3.141592653589793
        .long   1413754136   ; младшие 32 бита
        .long   1074340347   ; старшие 32 бита

.LC3:   ; 0.5 (а не 2.0!)
        .long   0
        .long   1071644672   ; → double 0.5
        ; Почему? Потому что (f(x_k)+f(x_{k+1})) / 2.0 = (f(x_k)+f(x_{k+1})) * 0.5
        ; Умножение быстрее деления → компилятор заменил деление на умножение на 0.5

.LC6:   ; 1e-9
        .long   -400107883
        .long   1041313291
main:
        push    rbp                 ; Сохраняем rbp (используется как временный регистр)
        push    rbx                 ; Сохраняем rbx (callee-saved)
        sub     rsp, 88             ; Выделяем 88 байт стека
        lea     rsi, [rsp+64]       ; &start (struct timespec)
        mov     edi, 4              ; CLOCK_MONOTONIC_RAW
        call    clock_gettime
        lea     rsi, [rsp+44]       ; &N (int)
        mov     edi, OFFSET FLAT:.LC1  ; "%d"
        mov     eax, 0              ; кол-во векторных регистров = 0
        call    __isoc99_scanf

        mov     edx, eax            ; edx = результат scanf
        mov     eax, 1              ; подготовка к возврату 1 при ошибке
        cmp     edx, 1
        jne     .L3                 ; если != 1 → ошибка → выход с return 1
        mov     ebp, DWORD PTR [rsp+44]   ; ebp = N (используем ebp как k и N)
        pxor    xmm0, xmm0                ; xmm0 = 0.0
        cvtsi2sd xmm0, ebp                ; xmm0 = (double)N
        movsd   xmm1, QWORD PTR .LC2[rip] ; xmm1 = M_PI
        divsd   xmm1, xmm0                ; xmm1 = M_PI / N
        movsd   QWORD PTR [rsp+24], xmm1  ; h → [rsp+24]
        test    ebp, ebp          ; if (N <= 0)
        jle     .L8               ; → прыгаем к выводу (интеграл = 0)
        mov     ebx, 0            ; ebx = k = 0
        mov     QWORD PTR [rsp], 0x000000000  ; integral = 0.0 (в [rsp])
.L6:
        ; x_k = k * h   (a = 0 → опущено!)
        pxor    xmm0, xmm0
        cvtsi2sd xmm0, ebx                ; xmm0 = (double)k
        movsd   xmm3, QWORD PTR [rsp+24]  ; xmm3 = h
        mulsd   xmm0, xmm3                ; xmm0 = k * h
        pxor    xmm2, xmm2                ; xmm2 = 0.0 (a = 0)
        addsd   xmm0, xmm2                ; xmm0 = x_k (но это избыточно! xmm2 = 0)
        ; ↑ компилятор мог убрать addsd, но оставил — возможно, из-за ABI или осторожности

        add     ebx, 1                    ; k+1

        ; x_{k+1} = (k+1) * h
        pxor    xmm1, xmm1
        cvtsi2sd xmm1, ebx                ; xmm1 = (double)(k+1)
        mulsd   xmm1, xmm3                ; xmm1 = (k+1)*h
        addsd   xmm1, xmm2                ; + 0 → x_{k+1}
        movsd   QWORD PTR [rsp+16], xmm1  ; сохраняем x_{k+1}

        ; f(x_k)
        call    f                         ; x_k уже в xmm0 → вызов f
        movsd   QWORD PTR [rsp+8], xmm0   ; сохраняем f(x_k)

        ; f(x_{k+1})
        movsd   xmm0, QWORD PTR [rsp+16]  ; загружаем x_{k+1}
        call    f                         ; f(x_{k+1}) → xmm0

        ; (f(x_k) + f(x_{k+1})) * 0.5
        addsd   xmm0, QWORD PTR [rsp+8]   ; f(x_k) + f(x_{k+1})
        mulsd   xmm0, QWORD PTR .LC3[rip] ; * 0.5

        ; integral += ...
        addsd   xmm0, QWORD PTR [rsp]     ; + текущий integral
        movsd   QWORD PTR [rsp], xmm0     ; обновляем integral

        cmp     ebp, ebx                  ; if (k != N) → продолжить
        jne     .L6
.L5:
        ; printf("a = %.10f, b = %.10f, h = %.10f\n", 0.0, M_PI, h);
        movsd   xmm2, QWORD PTR [rsp+24]  ; h
        movsd   xmm1, QWORD PTR .LC2[rip] ; b = M_PI
        pxor    xmm0, xmm0                ; a = 0.0
        mov     edi, OFFSET FLAT:.LC4
        mov     eax, 3                    ; 3 float-аргумента
        call    printf

        ; integral *= h
        movsd   xmm0, QWORD PTR [rsp+24]  ; h
        mulsd   xmm0, QWORD PTR [rsp]     ; h * integral
        mov     edi, OFFSET FLAT:.LC5
        mov     eax, 1
        call    printf
        lea     rsi, [rsp+48]       ; &end
        mov     edi, 4
        call    clock_gettime
        ; Наносекунды: end.tv_nsec - start.tv_nsec
        mov     rax, QWORD PTR [rsp+56]   ; end.tv_nsec
        sub     rax, QWORD PTR [rsp+72]   ; - start.tv_nsec
        pxor    xmm0, xmm0
        cvtsi2sd xmm0, rax                ; → double
        mulsd   xmm0, QWORD PTR .LC6[rip] ; * 1e-9

        ; Секунды: end.tv_sec - start.tv_sec
        mov     rax, QWORD PTR [rsp+48]   ; end.tv_sec
        sub     rax, QWORD PTR [rsp+64]   ; - start.tv_sec
        pxor    xmm1, xmm1
        cvtsi2sd xmm1, rax                ; → double

        addsd   xmm0, xmm1                ; общее время

        mov     edi, OFFSET FLAT:.LC7
        mov     eax, 1
        call    printf	
        mov     eax, 0        ; return 0
.L3:
        add     rsp, 88       ; восстановить стек
        pop     rbx           ; восстановить rbx
        pop     rbp           ; восстановить rbp
        ret
