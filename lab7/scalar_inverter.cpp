#include "matrix_inverter_common.hpp"

// === 1. SKALARNAYA REALIZATSIYA (NAIVE) ===

void mat_mul_scalar(const float* A, const float* B, float* C, int n) {
    // Используем fill_n для соответствия стилю C++ (Clang-Tidy)
    std::fill_n(C, n * n, 0.0f); // для обнуления C
    for (int i = 0; i < n; ++i) {
        for (int k = 0; k < n; ++k) {
            const float temp = A[i * n + k];
            for (int j = 0; j < n; ++j) {
                C[i * n + j] += temp * B[k * n + j];
            }
        }
    }
}

void invert_scalar(const float* A, float* Result, int n, int m) {
    // Используем static_cast для соответствия стилю C++ (Clang-Tidy)
    auto* B = static_cast<float *>(aligned_alloc_wrapper(n * n));
    auto* R = static_cast<float *>(aligned_alloc_wrapper(n * n));
    auto* Temp = static_cast<float *>(aligned_alloc_wrapper(n * n));
    auto* Term = static_cast<float *>(aligned_alloc_wrapper(n * n)); 

    // 1. Вычисление B
    transpose(A, B, n);
    const float n1 = norm_1(A, n);
    const float nInf = norm_inf(A, n);
    const float div = n1 * nInf;
    for(int i=0; i<n*n; ++i) B[i] /= div;

    // 2. Вычисление R = I - B*A
    mat_mul_scalar(B, A, Temp, n);

    for(int i=0; i<n; ++i) {
        for(int j=0; j<n; ++j) {
            const float identity = (i == j) ? 1.0f : 0.0f;
            R[i*n + j] = identity - Temp[i*n + j];
        }
    }

    // 3. Сумма ряда: Result = B + R*B + R^2*B ...
    std::memcpy(Term, B, n * n * sizeof(float));
    std::memcpy(Result, B, n * n * sizeof(float)); 

    for (int k = 0; k < m; ++k) {
        // Term_new = R * Term_old
        mat_mul_scalar(R, Term, Temp, n);
        std::memcpy(Term, Temp, n * n * sizeof(float));

        // Result += Term_new
        for(int i=0; i<n*n; ++i) Result[i] += Term[i];
    }

    free(B); free(R); free(Temp); free(Term);
}