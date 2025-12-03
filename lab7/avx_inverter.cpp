#include "matrix_inverter_common.hpp"

// === 2. VEKTORNAYA REALIZATSIYA (AVX Intrinsics) ===

void mat_mul_avx(const float* A, const float* B, float* C, int n) {
    // Используем fill_n для соответствия стилю C++ (Clang-Tidy)
    std::fill_n(C, n * n, 0.0f); 

    for (int i = 0; i < n; i += BLOCK_SIZE) {
        for (int k = 0; k < n; k += BLOCK_SIZE) {
            for (int j = 0; j < n; j += BLOCK_SIZE) {
                
                const int i_max = std::min(i + BLOCK_SIZE, n);
                const int k_max = std::min(k + BLOCK_SIZE, n);
                const int j_max = std::min(j + BLOCK_SIZE, n);

                for (int ii = i; ii < i_max; ++ii) {
                    for (int kk = k; kk < k_max; ++kk) {
                        // Загружаем один элемент A и "размножаем" его на весь вектор
                        const __m256 a_vec = _mm256_set1_ps(A[ii * n + kk]);

                        for (int jj = j; jj < j_max; jj += 8) {
                            const __m256 b_vec = _mm256_load_ps(&B[kk * n + jj]);
                            __m256 c_vec = _mm256_load_ps(&C[ii * n + jj]);

                            // C = C + A * B (FMA)
                            c_vec = _mm256_fmadd_ps(a_vec, b_vec, c_vec);
                            
                            _mm256_store_ps(&C[ii * n + jj], c_vec);
                        }
                    }
                }
            }
        }
    }
}


void invert_avx(const float* A, float* Result, int n, int m) {
    auto* B = static_cast<float*>(aligned_alloc_wrapper(n * n));
    auto* R = static_cast<float *>(aligned_alloc_wrapper(n * n));
    auto* Temp = static_cast<float *>(aligned_alloc_wrapper(n * n));
    auto* Term = static_cast<float *>(aligned_alloc_wrapper(n * n));

    transpose(A, B, n);
    const float n1 = norm_1(A, n);
    const float nInf = norm_inf(A, n);
    const float div = n1 * nInf;

    // Векторное деление для инициализации B
    const __m256 div_vec = _mm256_set1_ps(div);
    for(int i=0; i<n*n; i+=8) {
        const __m256 val = _mm256_load_ps(&B[i]);
        _mm256_store_ps(&B[i], _mm256_div_ps(val, div_vec));
    }

    // R = I - B*A
    mat_mul_avx(B, A, Temp, n);

    // Скалярное вычитание R = I - Temp
    for(int i=0; i<n; ++i) {
        for(int j=0; j<n; ++j) {
             const float identity = (i == j) ? 1.0f : 0.0f;
             R[i*n + j] = identity - Temp[i*n + j];
        }
    }

    std::memcpy(Term, B, n * n * sizeof(float));
    std::memcpy(Result, B, n * n * sizeof(float));

    for (int k = 0; k < m; ++k) {
        mat_mul_avx(R, Term, Temp, n);
        std::memcpy(Term, Temp, n * n * sizeof(float));

        // Векторное сложение Result += Term
        for(int i=0; i<n*n; i+=8) {
            const __m256 res_vec = _mm256_load_ps(&Result[i]);
            const __m256 term_vec = _mm256_load_ps(&Term[i]);
            _mm256_store_ps(&Result[i], _mm256_add_ps(res_vec, term_vec));
        }
    }

    free(B); free(R); free(Temp); free(Term);
}