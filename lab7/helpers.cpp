#include "matrix_inverter_common.hpp"

// Выравнивание памяти для AVX (32 байта)
void* aligned_alloc_wrapper(const size_t size) {
    void* ptr = nullptr;
    // posix_memalign требует 32-байтного выравнивания для AVX (256 бит)
    if (posix_memalign(&ptr, 32, size * sizeof(float))) {
        return nullptr;
    }
    return ptr;
}
// генерирует матрицу так, чтобы она обеспечивала диагональное  преобладание, что гарантирует обратимость и сходимость ряда Неймана
void generate_matrix(float* A, int n) {
    for (int i = 0; i < n * n; ++i) {
        // Диагональное преобладание для обратимости
        if (i % (n + 1) == 0) A[i] = static_cast<float>(i % 10) + 10.0f;
        else A[i] = 1.0f;
    }
}

// Транспонирование
void transpose(const float* src, float* dst, int n) {
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            dst[j * n + i] = src[i * n + j];
}

float norm_1(const float* A, int n) {
    float max_sum = 0.0f;
    for (int j = 0; j < n; ++j) {
        float col_sum = 0.0f;
        for (int i = 0; i < n; ++i) {
            col_sum += std::abs(A[i * n + j]);
        }
        if (col_sum > max_sum) max_sum = col_sum;
    }
    return max_sum;
}

float norm_inf(const float* A, const int n) {
    float max_sum = 0.0f;
    for (int i = 0; i < n; ++i) {
        float row_sum = 0.0f;
        for (int j = 0; j < n; ++j) {
            row_sum += std::abs(A[i * n + j]);
        }
        if (row_sum > max_sum) max_sum = row_sum;
    }
    return max_sum;
}