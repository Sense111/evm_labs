f:
        push    ebp                 ; Сохраняем старый базовый указатель
        mov     ebp, esp            ; Устанавливаем новый фрейм: ebp = esp
        sub     esp, 24             ; Выделяем 24 байта локального стека
        mov     eax, DWORD PTR [ebp+8]   ; Младшая половина x
        mov     edx, DWORD PTR [ebp+12]  ; Старшая половина x
        mov     DWORD PTR [ebp-16], eax  ; Сохраняем x в [ebp-16] (младш.)
        mov     DWORD PTR [ebp-12], edx  ; и [ebp-12] (старш.)
        sub     esp, 8              ; Выравнивание стека под вызов (16-байтное выравнивание не обязательно в 32-бит, но иногда делается)
        push    DWORD PTR [ebp-12]  ; Старшая половина x → стек (второй аргумент)
        push    DWORD PTR [ebp-16]  ; Младшая половина x → стек (первый аргумент)
        call    exp                 ; Вызов exp(x)
        add     esp, 16             ; Очистка стека: 8 байт аргументов + 8 байт выравнивания
        fstp    QWORD PTR [ebp-24]  ; Сохраняем результат exp(x) в [ebp-24] и выталкиваем из FPU
        sub     esp, 8
        push    DWORD PTR [ebp-12]  ; Снова кладём x на стек
        push    DWORD PTR [ebp-16]
        call    sin                 ; sin(x)
        add     esp, 16
        fmul    QWORD PTR [ebp-24]  ; st(0) = sin(x) * exp(x)  (exp(x) загружается из памяти)
        leave                       ; mov esp, ebp; pop ebp
        ret                         ; Возврат: результат в st(0).LC3:   .string "%d"                     ; для scanf
.LC3:   .string "%d"                     ; для scanf
.LC5:   .string "a = %.10f, b = %.10f, h = %.10f\n"
.LC6:   .base64 "..."                    ; "Приближённое значение интеграла: %.10f\n"
.LC8:   .string "Time taken: %lf sec.\n"
.LC2:   ; M_PI ≈ 3.141592653589793
        .long   1413754136   ; младшие 32 бита
        .long   1074340347   ; старшие 32 бита

.LC4:   ; 2.0
        .long   0
        .long   1073741824

.LC7:   ; 1e-9
        .long   -400107883
        .long   1041313291
main:
        lea     ecx, [esp+4]        ; Сохраняем оригинальный esp+4 (адрес возврата + argc)
        and     esp, -16            ; Выравниваем стек по 16-байтной границе (требование некоторых libc)
        push    DWORD PTR [ecx-4]   ; Восстанавливаем возвратный адрес
        push    ebp                 ; Сохраняем ebp
        mov     ebp, esp            ; Новый фрейм
        push    ecx                 ; Сохраняем ecx (для восстановления esp в конце)
        sub     esp, 100            ; Выделяем ~100 байт под локальные переменные и структуры
        sub     esp, 8
        lea     eax, [ebp-72]       ; &start (struct timespec: 8 байт = 2×long)
        push    eax
        push    4                   ; CLOCK_MONOTONIC_RAW
        call    clock_gettime
        add     esp, 16             ; Очистка: 8 (выравнивание) + 4 + 4
        fldz                        ; Загружаем 0.0 в st(0)
        fstp    QWORD PTR [ebp-32]  ; a = 0.0 → [ebp-32]

        fld     QWORD PTR .LC2      ; Загружаем M_PI
        fstp    QWORD PTR [ebp-40]  ; b = M_PI → [ebp-40]
        sub     esp, 8
        lea     eax, [ebp-84]       ; &N (int)
        push    eax
        push    OFFSET FLAT:.LC3    ; "%d"
        call    __isoc99_scanf
        add     esp, 16

        cmp     eax, 1
        je      .L4
        mov     eax, 1
        jmp     .L8                 ; Ошибка ввода → return 1
        sub     esp, 8
        lea     eax, [ebp-84]       ; &N (int)
        push    eax
        push    OFFSET FLAT:.LC3    ; "%d"
        call    __isoc99_scanf
        add     esp, 16

        cmp     eax, 1
        je      .L4
        mov     eax, 1
        jmp     .L8                 ; Ошибка ввода → return 1
.L4:
        fld     QWORD PTR [ebp-40]  ; b
        fsub    QWORD PTR [ebp-32]  ; b - a → st(0)

        mov     eax, DWORD PTR [ebp-84]  ; N
        mov     DWORD PTR [ebp-96], eax  ; временное хранилище для int→double

        fild    DWORD PTR [ebp-96]       ; Загружаем N как целое → конвертирует в double в st(0)
        fdivp   st(1), st                ; st(1) / st(0) → результат в st(0), pop

        fstp    QWORD PTR [ebp-48]       ; h = ... → [ebp-48]
        fldz
        fstp    QWORD PTR [ebp-16]       ; integral = 0.0

        mov     DWORD PTR [ebp-20], 0    ; k = 0
        jmp     .L6                      ; к проверке условия
.L7:
        ; x_k = a + k * h
        fild    DWORD PTR [ebp-20]       ; k → double в st(0)
        fmul    QWORD PTR [ebp-48]       ; k * h
        fld     QWORD PTR [ebp-32]       ; a
        faddp   st(1), st                ; a + k*h → st(0)
        fstp    QWORD PTR [ebp-56]       ; x_k → [ebp-56]

        ; x_{k+1} = a + (k+1)*h
        mov     eax, DWORD PTR [ebp-20]
        add     eax, 1
        mov     DWORD PTR [ebp-96], eax
        fild    DWORD PTR [ebp-96]       ; (k+1)
        fmul    QWORD PTR [ebp-48]       ; (k+1)*h
        fld     QWORD PTR [ebp-32]       ; a
        faddp   st(1), st                ; a + (k+1)*h
        fstp    QWORD PTR [ebp-64]       ; x_{k+1}
        ; Вызов f(x_k)
        sub     esp, 8
        push    DWORD PTR [ebp-52]       ; старшая часть x_k
        push    DWORD PTR [ebp-56]       ; младшая часть x_k
        call    f
        add     esp, 16
        fstp    QWORD PTR [ebp-96]       ; сохраняем f(x_k)        ; Вызов f(x_{k+1})
        sub     esp, 8
        push    DWORD PTR [ebp-60]       ; старшая часть x_{k+1}
        push    DWORD PTR [ebp-64]       ; младшая часть
        call    f
        add     esp, 16
        ; Теперь st(0) = f(x_{k+1})
        fld     QWORD PTR [ebp-96]       ; Загружаем f(x_k) → st(0), f(x_{k+1}) → st(1)
        faddp   st(1), st                ; f(x_k) + f(x_{k+1}) → st(0)

        fld     QWORD PTR .LC4           ; 2.0
        fdivp   st(1), st                ; (сумма) / 2.0

        fld     QWORD PTR [ebp-16]       ; текущий integral
        faddp   st(1), st                ; integral += ...

        fstp    QWORD PTR [ebp-16]       ; сохраняем обновлённый integral

        add     DWORD PTR [ebp-20], 1    ; k++
.L6:
        mov     eax, DWORD PTR [ebp-84]  ; N
        cmp     DWORD PTR [ebp-20], eax  ; k < N?
        jl      .L7                      ; да → продолжить
        fld     QWORD PTR [ebp-16]       ; integral
        fmul    QWORD PTR [ebp-48]       ; * h
        fstp    QWORD PTR [ebp-16]       ; сохранить
        sub     esp, 4
        push    DWORD PTR [ebp-44]       ; b (старшая)
        push    DWORD PTR [ebp-48]       ; h (младшая) ← ОШИБКА? НЕТ: на самом деле:
        ; Правильный порядок (от старшего к младшему для каждого double):
        ; a: [ebp-28] (старш.), [ebp-32] (младш.)
        ; b: [ebp-36], [ebp-40]
        ; h: [ebp-44], [ebp-48]
        push    DWORD PTR [ebp-36]       ; b старш.
        push    DWORD PTR [ebp-40]       ; b младш.
        push    DWORD PTR [ebp-28]       ; a старш.
        push    DWORD PTR [ebp-32]       ; a младш.
        push    OFFSET FLAT:.LC5
        call    printf
        add     esp, 32                  ; 6×4 = 24 + 4 (выравнивание?) → итого 32
        sub     esp, 4
        push    DWORD PTR [ebp-12]       ; integral старшее
        push    DWORD PTR [ebp-16]       ; integral младшее
        push    OFFSET FLAT:.LC6
        call    printf
        add     esp, 16
        sub     esp, 4
        push    DWORD PTR [ebp-12]       ; integral старшее
        push    DWORD PTR [ebp-16]       ; integral младшее
        push    OFFSET FLAT:.LC6
        call    printf
        add     esp, 16
        ; Секунды: end.tv_sec - start.tv_sec
        mov     edx, DWORD PTR [ebp-80]   ; end.tv_sec
        mov     eax, DWORD PTR [ebp-72]   ; start.tv_sec
        sub     edx, eax
        mov     DWORD PTR [ebp-96], edx
        fild    DWORD PTR [ebp-96]        ; → st(0)

        ; Наносекунды: end.tv_nsec - start.tv_nsec
        mov     edx, DWORD PTR [ebp-76]   ; end.tv_nsec
        mov     eax, DWORD PTR [ebp-68]   ; start.tv_nsec
        sub     edx, eax
        mov     DWORD PTR [ebp-96], edx
        fild    DWORD PTR [ebp-96]        ; → st(0), секунды → st(1)

        fld     QWORD PTR .LC7            ; 1e-9 → st(0)
        fmulp   st(1), st                 ; нс * 1e-9 → st(0), секунды → st(1)
        faddp   st(1), st                 ; общее время → st(0)
        sub     esp, 4
        lea     esp, [esp-8]              ; резервируем 8 байт на стеке
        fstp    QWORD PTR [esp]           ; сохраняем время в стек (для printf)
        push    OFFSET FLAT:.LC8
        call    printf
        add     esp, 16
        mov     eax, 0                    ; return 0
.L8:
        mov     ecx, DWORD PTR [ebp-4]    ; восстанавливаем сохранённый ecx
        leave                             ; восстановить ebp и esp
        lea     esp, [ecx-4]              ; восстановить оригинальный esp
        ret

