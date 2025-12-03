#include "matrix_inverter_common.hpp"
#include <iostream>
#include <chrono>

int main() {
    // Используем static_cast для соответствия стилю C++ (Clang-Tidy)
    auto* A = static_cast<float *>(aligned_alloc_wrapper(N * N));
    auto* Result = static_cast<float *>(aligned_alloc_wrapper(N * N));

    generate_matrix(A, N);

    std::cout << "Matrix size: " << N << "x" << N << ", Iterations: " << M << std::endl;

    // 1. Scalar
    auto start = std::chrono::high_resolution_clock::now();
    invert_scalar(A, Result, N, M);
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff = end - start;
    std::cout << "Scalar Time: " << diff.count() << " s" << std::endl;

    // 2. AVX
    start = std::chrono::high_resolution_clock::now();
    invert_avx(A, Result, N, M);
    end = std::chrono::high_resolution_clock::now();
    diff = end - start;
    std::cout << "AVX Time:    " << diff.count() << " s" << std::endl;

    // 3. BLAS
    start = std::chrono::high_resolution_clock::now();
    invert_blas(A, Result, N, M);
    end = std::chrono::high_resolution_clock::now();
    diff = end - start;
    std::cout << "BLAS Time:   " << diff.count() << " s" << std::endl;

    free(A); free(Result);
    return 0;
}