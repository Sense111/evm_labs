#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <x86intrin.h>


const int    ELEMS_PER_FRAG = 262144;
const int    OFFSET_ELEMS   = 4*1024*1024; // 16 МБ / 4 = 4 194 216 элементов
const int    MAX_N          = 32;
const int    REPS           = 20000;     // 20 тысяч проходов

uint32_t* arr;

int main() {
    arr = (uint32_t*)malloc((size_t)(OFFSET_ELEMS * (MAX_N - 1) + ELEMS_PER_FRAG) * 4);
    if (!arr) { printf("Нет памяти!\n"); return 1; }

    printf("N\tCycles_per_access\n");

    for (int n = 1; n <= MAX_N; n++) {
        for (int i = 0; i < ELEMS_PER_FRAG; i++) {
            for (int f = 0; f < n; f++) {
                int next_f = (f + 1) % n;
                int next_i = (f == n - 1) ? (i + 1) % ELEMS_PER_FRAG : i;
                arr[f * OFFSET_ELEMS + i] = next_f * OFFSET_ELEMS + next_i;
            }
        }

        volatile uint32_t idx = 0;
        long long steps = (long long)n * ELEMS_PER_FRAG;

        // Прогрев
        for (long long j = 0; j < steps; j++) idx = arr[idx];

        _mm_lfence();
        uint64_t start = __rdtsc();

        for (int r = 0; r < REPS; r++) {
            for (long long j = 0; j < steps; j++) {
                idx = arr[idx];
            }
        }

        uint64_t end = __rdtsc();
        _mm_lfence();

        double avg = (double)(end - start) / (REPS * steps);
        printf("%d\t%.3f\n", n, avg);
    }

    free(arr);
    return 0;
}
