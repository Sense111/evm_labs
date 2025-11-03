f:
        sub     rsp, 24
        movsd   QWORD PTR [rsp+8], xmm0   ; сохраняем x
        call    exp                       ; exp(x)
        movsd   QWORD PTR [rsp], xmm0     ; сохраняем exp(x)
        movsd   xmm0, QWORD PTR [rsp+8]   ; загружаем x
        call    sin                       ; sin(x)
        mulsd   xmm0, QWORD PTR [rsp]     ; sin(x) * exp(x)
        add     rsp, 24
        ret
.LC1:   .string "%d"
.LC4:   .string "a = %.10f, b = %.10f, h = %.10f\n"
.LC5:   .base64 "..."  ; русская строка
.LC7:   .string "Time taken: %lf sec.\n"

.LC2:   ; M_PI
        .long   1413754136
        .long   1074340347

.LC3:   ; 0.5
        .long   0
        .long   1071644672

.LC6:   ; 1e-9
        .long   -400107883
        .long   1041313291
main:
        push    rbp
        mov     edi, 4          ; CLOCK_MONOTONIC_RAW
        push    rbx
        sub     rsp, 120        ; выделяем 120 байт
        lea     rsi, [rsp+80]   ; &start
        call    clock_gettime
        xor     eax, eax        ; eax = 0 (для scanf)
        lea     rsi, [rsp+76]   ; &N
        mov     edi, OFFSET FLAT:.LC1
        call    __isoc99_scanf
        cmp     eax, 1
        jne     .L11            ; ошибка → return 1
        mov     ebp, DWORD PTR [rsp+76]   ; ebp = N
        movsd   xmm2, QWORD PTR .LC2[rip] ; xmm2 = M_PI
        pxor    xmm0, xmm0
        cvtsi2sd xmm0, ebp                ; xmm0 = (double)N
        divsd   xmm2, xmm0                ; xmm2 = M_PI / N → h
        test    ebp, ebp
        jle     .L9            ; если N <= 0 → integral = 0
        mov     QWORD PTR [rsp+16], 0x000000000  ; integral = 0.0
        xor     ebx, ebx       ; ebx = k = 0
        pxor    xmm1, xmm1     ; xmm1 = 0.0 → будет x_k = k * h
.L7:
        mulsd   xmm1, xmm2     ; xmm1 = x_k = k * h   (на первой итерации: 0 * h = 0)
        pxor    xmm3, xmm3     ; xmm3 = 0.0 (a = 0)
        pxor    xmm4, xmm4     ; xmm4 = 0.0
        add     ebx, 1         ; k = k + 1
        movsd   QWORD PTR [rsp+48], xmm2   ; сохраняем h (зачем? возможно, для восстановления)
        addsd   xmm3, xmm1                 ; xmm3 = x_k (т.к. xmm3 = 0)
        pxor    xmm1, xmm1
        cvtsi2sd xmm1, ebx                 ; xmm1 = (double)(k+1)
        movapd  xmm0, xmm1                 ; копия (k+1)
        movsd   QWORD PTR [rsp+56], xmm1   ; сохраняем (k+1) как double
        mulsd   xmm0, xmm2                 ; xmm0 = (k+1) * h = x_{k+1}
        movsd   QWORD PTR [rsp+32], xmm3   ; [rsp+32] = x_k
        addsd   xmm0, xmm4                 ; xmm0 = x_{k+1} (xmm4 = 0)
        movsd   QWORD PTR [rsp+8], xmm0    ; [rsp+8] = x_{k+1}
        movapd  xmm0, xmm3        ; xmm0 = x_k
        call    exp               ; exp(x_k)
        movsd   QWORD PTR [rsp+24], xmm0   ; сохраняем exp(x_k)
        movsd   xmm0, QWORD PTR [rsp+32]   ; xmm0 = x_k
        call    sin               ; sin(x_k)
        movsd   QWORD PTR [rsp+32], xmm0   ; сохраняем sin(x_k)
        movsd   xmm0, QWORD PTR [rsp+8]    ; xmm0 = x_{k+1}
        call    exp
        movsd   QWORD PTR [rsp+40], xmm0   ; exp(x_{k+1})
        movsd   xmm0, QWORD PTR [rsp+8]    ; снова x_{k+1}
        call    sin
        ; xmm0 = sin(x_{k+1})
        movsd   xmm3, QWORD PTR [rsp+24]   ; exp(x_k)
        cmp     ebp, ebx                   ; проверка условия цикла (рано!)
        movsd   xmm2, QWORD PTR [rsp+48]   ; восстанавливаем h в xmm2
        mulsd   xmm0, QWORD PTR [rsp+40]   ; sin(x_{k+1}) * exp(x_{k+1}) = f(x_{k+1})
        movsd   xmm1, QWORD PTR [rsp+56]   ; (k+1) — не используется дальше?
        mulsd   xmm3, QWORD PTR [rsp+32]   ; exp(x_k) * sin(x_k) = f(x_k)
        addsd   xmm0, xmm3                 ; f(x_k) + f(x_{k+1})
        mulsd   xmm0, QWORD PTR .LC3[rip]  ; * 0.5
        addsd   xmm0, QWORD PTR [rsp+16]   ; + integral
        movsd   QWORD PTR [rsp+16], xmm0   ; обновляем integral
        jne     .L7                        ; если k != N → продолжить
.L6:
        pxor    xmm0, xmm0                ; a = 0.0
        mov     edi, OFFSET FLAT:.LC4
        mov     eax, 3
        movsd   xmm1, QWORD PTR .LC2[rip] ; b = M_PI
        movsd   QWORD PTR [rsp+8], xmm2   ; сохраняем h
        call    printf

        movsd   xmm0, QWORD PTR [rsp+16]  ; integral
        mulsd   xmm0, QWORD PTR [rsp+8]   ; * h
        mov     edi, OFFSET FLAT:.LC5
        mov     eax, 1
        call    printf
        lea     rsi, [rsp+96]             ; &end
        mov     edi, 4
        call    clock_gettime
        mov     rax, QWORD PTR [rsp+104]  ; end.tv_nsec
        pxor    xmm0, xmm0
        sub     rax, QWORD PTR [rsp+88]   ; - start.tv_nsec
        cvtsi2sd xmm0, rax
        pxor    xmm1, xmm1
        mov     rax, QWORD PTR [rsp+96]   ; end.tv_sec
        sub     rax, QWORD PTR [rsp+80]   ; - start.tv_sec
        mulsd   xmm0, QWORD PTR .LC6[rip] ; нс * 1e-9
        cvtsi2sd xmm1, rax                ; секунды
        mov     edi, OFFSET FLAT:.LC7
        mov     eax, 1
        addsd   xmm0, xmm1                ; общее время
        call    printf
        xor     eax, eax    ; return 0
        jmp     .L4
.L11:
        mov     eax, 1      ; return 1
.L4:
        add     rsp, 120
        pop     rbx
        pop     rbp
        ret
