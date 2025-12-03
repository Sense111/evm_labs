#pragma once

#include <iostream>
#include <cmath>
#include <chrono>
#include <cstring>
#include <algorithm>
#include <x86intrin.h> // Для AVX Intrinsics
#include <openblas/cblas.h> // Для BLAS
#include <stdlib.h> // Для posix_memalign

// Размер матрицы и число итераций согласно заданию
constexpr int N = 2048;
constexpr int M = 10;
constexpr int BLOCK_SIZE = 64; // Для блочного AVX умножения

// Выравнивание памяти для AVX (32 байта)
void* aligned_alloc_wrapper(const size_t size);

// === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
void generate_matrix(float* A, int n);
void transpose(const float* src, float* dst, int n);
float norm_1(const float* A, int n);
float norm_inf(const float* A, int n);



// Скалярная
void mat_mul_scalar(const float* A, const float* B, float* C, int n);
void invert_scalar(const float* A, float* Result, int n, int m);

// AVX
void mat_mul_avx(const float* A, const float* B, float* C, int n);
void invert_avx(const float* A, float* Result, int n, int m);

// BLAS
void invert_blas(const float* A, float* Result, int n, int m);