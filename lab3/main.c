#include <stdio.h>
#define M_PI 3.14159265358979323846
#include <math.h>
#include <time.h>

double f(double x) {
    return exp(x) * sin(x);
}

int main() {
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC_RAW, &start);
    double a = 0.0;
    double b = M_PI;
    int N;
    if (scanf("%d", &N) != 1) {
        return 1;
    };

    double h = (b - a) / N;
    double integral = 0.0;

    for (int k = 0; k < N; k++) {
        double x_k = a + k * h;
        double x_k1 = a + (k + 1) * h;
        integral += (f(x_k) + f(x_k1)) / 2.0;
    }
    integral *= h;

    printf("a = %.10f, b = %.10f, h = %.10f\n", a, b, h);
    printf("Приближённое значение интеграла: %.10f\n", integral);

    clock_gettime(CLOCK_MONOTONIC_RAW, &end);
    printf("Time taken: %lf sec.\n",
           end.tv_sec - start.tv_sec
           + 0.000000001 * (end.tv_nsec - start.tv_nsec));

    return 0;
}
