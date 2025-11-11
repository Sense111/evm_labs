#include <iostream>
#include <vector>
#include <iomanip>
#include <random>
#include <algorithm>
#include <climits>
#include <cstdint>
using namespace std;
inline uint64_t rdtscp() {
    unsigned int lo, hi;
    __asm__ __volatile__ ("rdtscp" : "=a" (lo), "=d" (hi) :: "rcx");
    return ((uint64_t)hi << 32) | lo;
}
void warm_cache(const vector<int>& arr, int N) {
    volatile int k = 0;
    for (int i = 0; i < N; ++i) k = arr[k];
}
uint64_t measure(const vector<int>& arr, int N, int K) {
    warm_cache(arr, N);
    volatile int k = 0;
    uint64_t start = rdtscp();
    for (long long i = 0; i < (long long)N * K; ++i)
        k = arr[k];
    uint64_t end = rdtscp();
    return end - start;
}
void fill_forward(vector<int>& arr, int N) {
    for (int i = 0; i < N - 1; ++i) arr[i] = i + 1;
    arr[N-1] = 0;
}
void fill_backward(vector<int>& arr, int N) {
    arr[0] = N - 1;
    for (int i = 1; i < N; ++i) arr[i] = i - 1;
}
void fill_random(vector<int>& arr, int N) {
    vector<int> order(N);
    for (int i = 0; i < N; ++i) order[i] = i;
    static thread_local std::mt19937 gen(std::random_device{}());
    std::shuffle(order.begin(), order.end(), gen);
    for (int i = 0; i < N - 1; ++i)
        arr[order[i]] = order[i + 1];
    arr[order[N - 1]] = order[0];
}
int get_K(int N) {
    if (N < 65536) return 100;
    if (N < 1048576) return 30;
    if (N < 4194304) return 10;
    return 5;
}
int main() {
    constexpr int REPEATS = 3;
    constexpr int N_MIN = 256;
    constexpr int N_MAX = 8'388'608; // 32 MB
    cout << "N\tforward\tbackward\trandom\n";
    cout << fixed << setprecision(2);
    int n = N_MIN;
    while (n <= N_MAX) {
        int K = get_K(n);
        vector<int> arr(n);
        uint64_t best[3] = {ULLONG_MAX, ULLONG_MAX, ULLONG_MAX};
        for (int rep = 0; rep < REPEATS; ++rep) {
            fill_forward(arr, n);
            uint64_t t = measure(arr, n, K);
            if (t < best[0]) best[0] = t;
            fill_backward(arr, n);
            t = measure(arr, n, K);
            if (t < best[1]) best[1] = t;
            fill_random(arr, n);
            t = measure(arr, n, K);
            if (t < best[2]) best[2] = t;
        }
        cout << n << "\t"
             << (double)best[0] / (n * K) << "\t"
             << (double)best[1] / (n * K) << "\t"
             << (double)best[2] / (n * K) << "\n";
        // Адаптивный шаг
        if (n < 8192) n += 512;
        else if (n < 65536) n += 2048;
        else if (n < 524288) n += 8192;
        else if (n < 2097152) n += 32768;
        else if (n < 8000000) n += 131072;
        else n += 262144;
    }
    return 0;
}
