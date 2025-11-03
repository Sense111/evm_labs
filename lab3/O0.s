f:
        push    rbp                 ; Сохраняем старый базовый указатель (начало функции)
        mov     rbp, rsp            ; Устанавливаем новый rbp = rsp (начало стекового фрейма)
        sub     rsp, 16             ; Выделяем 16 байт локального стека (для двух double: x и exp(x))
        movsd   QWORD PTR [rbp-8], xmm0  ; Сохраняем аргумент x (передан в xmm0) в [rbp-8]
        mov     rax, QWORD PTR [rbp-8]   ; Загружаем x как целое (битовое представление)
        movq    xmm0, rax           ; Передаём x в xmm0 (для вызова exp)
        call    exp                 ; Вызываем exp(x)
        movsd   QWORD PTR [rbp-16], xmm0 ; Сохраняем результат exp(x) в [rbp-16]
        mov     rax, QWORD PTR [rbp-8]   ; Снова загружаем x
        movq    xmm0, rax           ; Передаём x в xmm0
        call    sin                 ; Вызываем sin(x)
        mulsd   xmm0, QWORD PTR [rbp-16] ; Умножаем sin(x) * exp(x)
        leave                       ; Восстанавливаем rsp и rbp (эквивалентно mov rsp, rbp; pop rbp)
        ret                         ; Возвращаем результат в xmm0

.LC2:
        .string "%d"                ; Формат для scanf("%d", &N)
.LC4:
        .string "a = %.10f, b = %.10f, h = %.10f\n"  ; Формат вывода a, b, h
.LC5:
        .base64 "0J/RgNC40LHQu9C40LbRkdC90L3QvtC1INC30L3QsNGH0LXQvdC40LUg0LjQvdGC0LXQs9GA0LDQu9CwOiAlLjEwZgoA"
        ; Base64-кодированная строка на русском: "Приближённое значение интеграла: %.10f\n"
.LC7:
        .string "Time taken: %lf sec.\n"  ; Формат вывода времени
.LC1:
        .long   1413754136          ; Младшие 32 бита числа M_PI ≈ 3.141592653589793
        .long   1074340347          ; Старшие 32 бита → вместе это double M_PI
.LC3:
        .long   0                   ; Младшие 32 бита числа 2.0
        .long   1073741824          ; Старшие 32 бита → double 2.0 (используется для деления на 2)
.LC6:
        .long   -400107883          ; Младшие 32 бита числа 1e-9
        .long   1041313291          ; Старшие 32 бита → double 1e-9 (для перевода наносекунд в секунды)

main:
        push    rbp                 ; Сохраняем rbp
        mov     rbp, rsp            ; Начало фрейма main
        add     rsp, -128           ; Выделяем 128 байт стека (для локальных переменных и timespec)
        lea     rax, [rbp-80]       ; Адрес start (struct timespec занимает 16 байт: 8+8)
        mov     rsi, rax            ; rsi = &start
        mov     edi, 4              ; CLOCK_MONOTONIC_RAW = 4
        call    clock_gettime       ; clock_gettime(4, &start)
        pxor    xmm0, xmm0          ; xmm0 = 0.0
        movsd   QWORD PTR [rbp-24], xmm0  ; a = 0.0 → [rbp-24]
        movsd   xmm0, QWORD PTR .LC1[rip] ; Загружаем M_PI
        movsd   QWORD PTR [rbp-32], xmm0  ; b = M_PI → [rbp-32]
        lea     rax, [rbp-100]      ; Адрес переменной N (int)
        mov     rsi, rax            ; rsi = &N
        mov     edi, OFFSET FLAT:.LC2 ; edi = "%d"
        mov     eax, 0              ; Количество векторных регистров = 0
        call    __isoc99_scanf      ; scanf("%d", &N)
        cmp     eax, 1              ; Проверка: успешно ли прочитано 1 значение?
        je      .L4                 ; Если да — продолжаем
        mov     eax, 1              ; Иначе возвращаем 1
        jmp     .L8                 ; Выход из main
.L4:
        movsd   xmm0, QWORD PTR [rbp-32] ; xmm0 = b
        subsd   xmm0, QWORD PTR [rbp-24] ; xmm0 = b - a
        mov     eax, DWORD PTR [rbp-100] ; eax = N
        pxor    xmm1, xmm1          ; xmm1 = 0.0
        cvtsi2sd xmm1, eax          ; xmm1 = (double)N
        divsd   xmm0, xmm1          ; xmm0 = (b - a) / N
        movsd   QWORD PTR [rbp-40], xmm0 ; h = ... → [rbp-40]
        pxor    xmm0, xmm0          ; xmm0 = 0.0
        movsd   QWORD PTR [rbp-8], xmm0  ; integral = 0.0 → [rbp-8]
        mov     DWORD PTR [rbp-12], 0    ; k = 0 → [rbp-12]
        jmp     .L6                 ; Переход к проверке цикла
.L7: ; Начало итерации цикла for (k = 0; k < N; k++)
        ; Вычисление x_k = a + k * h
        pxor    xmm0, xmm0
        cvtsi2sd xmm0, DWORD PTR [rbp-12] ; xmm0 = (double)k
        mulsd   xmm0, QWORD PTR [rbp-40]  ; xmm0 = k * h
        movsd   xmm1, QWORD PTR [rbp-24]  ; xmm1 = a
        addsd   xmm0, xmm1                ; xmm0 = a + k*h
        movsd   QWORD PTR [rbp-48], xmm0  ; x_k → [rbp-48]

        ; Вычисление x_{k+1} = a + (k+1)*h
        mov     eax, DWORD PTR [rbp-12]   ; eax = k
        add     eax, 1                    ; eax = k+1
        pxor    xmm0, xmm0
        cvtsi2sd xmm0, eax                ; xmm0 = (double)(k+1)
        mulsd   xmm0, QWORD PTR [rbp-40]  ; xmm0 = (k+1)*h
        movsd   xmm1, QWORD PTR [rbp-24]  ; xmm1 = a
        addsd   xmm0, xmm1                ; xmm0 = a + (k+1)*h
        movsd   QWORD PTR [rbp-56], xmm0  ; x_{k+1} → [rbp-56]

        ; Вычисление f(x_k)
        mov     rax, QWORD PTR [rbp-48]   ; Загружаем x_k как целое
        movq    xmm0, rax                 ; Передаём в xmm0
        call    f                         ; f(x_k)
        movsd   QWORD PTR [rbp-120], xmm0 ; Сохраняем f(x_k)

        ; Вычисление f(x_{k+1})
        mov     rax, QWORD PTR [rbp-56]   ; x_{k+1}
        movq    xmm0, rax
        call    f                         ; f(x_{k+1})
        addsd   xmm0, QWORD PTR [rbp-120] ; f(x_k) + f(x_{k+1})

        ; Деление на 2.0
        movsd   xmm1, QWORD PTR .LC3[rip] ; xmm1 = 2.0
        divsd   xmm0, xmm1                ; (f(x_k)+f(x_{k+1}))/2

        ; Прибавление к интегралу
        movsd   xmm1, QWORD PTR [rbp-8]   ; текущий integral
        addsd   xmm0, xmm1                ; integral += ...
        movsd   QWORD PTR [rbp-8], xmm0   ; обновляем integral

        ; Инкремент k
        add     DWORD PTR [rbp-12], 1
.L6:
        mov     eax, DWORD PTR [rbp-100]  ; eax = N
        cmp     DWORD PTR [rbp-12], eax   ; сравнить k и N
        jl      .L7                       ; если k < N → продолжить цикл
        movsd   xmm0, QWORD PTR [rbp-8]   ; integral
        mulsd   xmm0, QWORD PTR [rbp-40]  ; integral *= h
        movsd   QWORD PTR [rbp-8], xmm0   ; сохранить результат
        movsd   xmm1, QWORD PTR [rbp-40]  ; h
        movsd   xmm0, QWORD PTR [rbp-32]  ; b
        mov     rax, QWORD PTR [rbp-24]   ; a (в целом виде)
        movapd  xmm2, xmm1                ; xmm2 = h
        movapd  xmm1, xmm0                ; xmm1 = b
        movq    xmm0, rax                 ; xmm0 = a
        mov     edi, OFFSET FLAT:.LC4     ; формат строки
        mov     eax, 3                    ; 3 аргумента с плавающей точкой
        call    printf
        mov     rax, QWORD PTR [rbp-8]    ; integral (биты)
        movq    xmm0, rax                 ; передать в xmm0
        mov     edi, OFFSET FLAT:.LC5     ; русская строка с форматом
        mov     eax, 1                    ; 1 float-аргумент
        call    printf
        mov     rax, QWORD PTR [rbp-8]    ; integral (биты)
        movq    xmm0, rax                 ; передать в xmm0
        mov     edi, OFFSET FLAT:.LC5     ; русская строка с форматом
        mov     eax, 1                    ; 1 float-аргумент
        call    printf
        lea     rax, [rbp-96]             ; &end (struct timespec)
        mov     rsi, rax
        mov     edi, 4
        call    clock_gettime             ; clock_gettime(4, &end)
        mov     rdx, QWORD PTR [rbp-96]   ; end.tv_sec
        mov     rax, QWORD PTR [rbp-80]   ; start.tv_sec
        sub     rdx, rax                  ; секунды: end.tv_sec - start.tv_sec → rdx

        pxor    xmm1, xmm1
        cvtsi2sd xmm1, rdx                ; xmm1 = (double)(секунды)

        mov     rdx, QWORD PTR [rbp-88]   ; end.tv_nsec
        mov     rax, QWORD PTR [rbp-72]   ; start.tv_nsec
        sub     rdx, rax                  ; наносекунды: end.tv_nsec - start.tv_nsec

        pxor    xmm2, xmm2
        cvtsi2sd xmm2, rdx                ; xmm2 = (double)(нс)

        movsd   xmm0, QWORD PTR .LC6[rip] ; xmm0 = 1e-9
        mulsd   xmm0, xmm2                ; нс → сек: 1e-9 * нс
        addsd   xmm1, xmm0                ; общее время = сек + нс*1e-9

        movq    rax, xmm1                 ; биты результата
        movq    xmm0, rax                 ; передать в xmm0 для printf
        mov     edi, OFFSET FLAT:.LC7     ; "Time taken: %lf sec.\n"
        mov     eax, 1                    ; 1 float-аргумент
        call    printf
        mov     eax, 0                    ; return 0
.L8:
        leave                             ; восстановить стек
        ret                               ; выход
