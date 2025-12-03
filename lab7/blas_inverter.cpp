#include "matrix_inverter_common.hpp"

// === 3. BLAS REALIZATSIYA ===

void invert_blas(const float* A, float* Result, int n, int m) {
    auto* B = static_cast<float *>(aligned_alloc_wrapper(n * n));
    auto* R = static_cast<float *>(aligned_alloc_wrapper(n * n));
    auto* Temp = static_cast<float *>(aligned_alloc_wrapper(n * n));
    auto* Term = static_cast<float *>(aligned_alloc_wrapper(n * n));

    transpose(A, B, n);
    const float n1 = norm_1(A, n);
    const float nInf = norm_inf(A, n);
    const float div = n1 * nInf;
    
    // BLAS scale: B = (1.0f/div) * B
    cblas_sscal(n*n, 1.0f/div, B, 1); 

    // Temp = B * A
    // SGEMM: C = alpha*A*B + beta*C. Здесь C=Temp, alpha=1.0f, A=B, B=A, beta=0.0f
    cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                n, n, n, 1.0f, B, n, A, n, 0.0f, Temp, n);

    // R = I - Temp (скалярно)
    for(int i=0; i<n*n; ++i) R[i] = -Temp[i];
    for(int i=0; i<n; ++i) R[i*n + i] += 1.0f;

    std::memcpy(Term, B, n * n * sizeof(float));
    std::memcpy(Result, B, n * n * sizeof(float));


    for (int k = 0; k < m; ++k) {
        // Temp = R * Term
        // SGEMM: C=Temp, alpha=1.0f, A=R, B=Term, beta=0.0f
        cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                    n, n, n, 1.0f, R, n, Term, n, 0.0f, Temp, n);
        std::memcpy(Term, Temp, n * n * sizeof(float));

        // Result = Result + Term
        // SAXPY: Y = alpha*X + Y. Здесь Y=Result, alpha=1.0f, X=Term
        cblas_saxpy(n*n, 1.0f, Term, 1, Result, 1);
    }

    free(B); free(R); free(Temp); free(Term);
}