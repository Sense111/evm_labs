#include <iostream>
#include <vector>
#include <random>
#include <algorithm>
#include <iomanip>
#include <fstream>
#include <stdint.h>
#include <numeric>

// --- КОНСТАНТЫ НАСТРОЙКИ ТЕСТА ---
constexpr size_t ARRAY_SIZE_ELEMENTS = 16 * 1024 * 1024;
constexpr int MAX_NOPS = 512;
constexpr int NOP_STEP = 4; // Шаг для NOP-ов
constexpr int NUM_ITERATIONS = 50000;

// --- ФУНКЦИИ ИЗМЕРЕНИЯ И ИНИЦИАЛИЗАЦИИ ---

static inline uint64_t rdtscp(uint32_t * aux) {
    uint32_t low, high;

    asm volatile ("rdtscp" : "=a" (low), "=d" (high), "=c" (*aux));
    return (static_cast<uint64_t>(high) << 32) | low;
}

static inline void serialize_pipeline() {
    asm volatile ("cpuid" : : : "%eax", "%ebx", "%ecx", "%edx");
}

void initialize_array(std::vector<size_t>& a, size_t size) {
    std::vector<size_t> indices(size);
    std::iota(indices.begin(), indices.end(), 0);

    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(indices.begin(), indices.end(), g);

    for (size_t i = 0; i < size - 1; ++i) {
        a[indices[i]] = indices[i+1];
    }
    a[indices[size - 1]] = indices[0];

}

void run_rob_test(std::vector<size_t>& a) {

    std::ofstream file("result.csv");
    file << "N_NOPS,Average_Cycles_Per_Load\n";

    volatile size_t k_start = 0;
    uint32_t aux; // Для rdtscp

    for (int N = 0; N <= MAX_NOPS; N += NOP_STEP) {
        uint64_t start_time, end_time;
        volatile size_t k = k_start;

        // Прогрев ROB и конвейера перед замером
        for (int i = 0; i < 1000; ++i) {
            k = a[k];
        }

        // --- НАЧАЛО ЗАМЕРА ---
        serialize_pipeline();
        start_time = rdtscp(&aux);

        // --- КРИТИЧЕСКИЙ ЦИКЛ ТЕСТА  ---
        for (int i = 0; i < NUM_ITERATIONS; ++i) {

            k = a[k];

            for (int j = 0; j < N; ++j) {
                asm volatile ("nop" : : : );
            }
        }

        end_time = rdtscp(&aux);
        serialize_pipeline();
        // --- КОНЕЦ ЗАМЕРА ---

        k_start = k % a.size();

        uint64_t total_cycles = end_time - start_time;

        double avg_cycles_per_load = static_cast<double>(total_cycles) / (1.0 * NUM_ITERATIONS);

        std::cout << "Nops: " << std::setw(4) << N << " Cycles/Load: " << std::fixed << std::setprecision(2) << avg_cycles_per_load << "\n";
        file << N << "," << avg_cycles_per_load << "\n";
    }
    file.close();
}

// --- MAIN ---

int main() {
    std::ios_base::sync_with_stdio(false);
    std::cin.tie(nullptr);

    std::vector<size_t> a(ARRAY_SIZE_ELEMENTS);

    initialize_array(a, ARRAY_SIZE_ELEMENTS);

    run_rob_test(a);

    return EXIT_SUCCESS;
}