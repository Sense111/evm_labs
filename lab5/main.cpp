#include <opencv2/opencv.hpp>
#include <iostream>
#include <chrono>
#include <locale>

int main() {
    setlocale(LC_ALL,"ru");
    cv::VideoCapture cap(0);
    if (!cap.isOpened()) {
        std::cerr << "Ошибка: не удалось открыть камеру." << std::endl;
        return -1;
    }

    cv::namedWindow("Original", cv::WINDOW_AUTOSIZE);
    cv::namedWindow("Processed", cv::WINDOW_AUTOSIZE);

    const int NUM_FRAMES = 300;
    int frameCount = 0;

    double total_capture = 0.0;
    double total_process = 0.0;
    double total_show = 0.0;

    auto wall_start = std::chrono::high_resolution_clock::now();

    while (frameCount < NUM_FRAMES) {
        // --- 1. Захват кадра ---
        auto t0 = std::chrono::high_resolution_clock::now();
        cv::Mat frame;
        cap >> frame;
        auto t1 = std::chrono::high_resolution_clock::now();
        if (frame.empty()) {
            std::cerr << "Пустой кадр." << std::endl;
            break;
        }

        // --- 2. Преобразование ---
        cv::Mat processed = frame.clone();
        std::vector<cv::Mat> channels;
        cv::split(processed, channels);
        channels[0] = cv::Scalar(0); // Blue = 0
        channels[2] = cv::Scalar(0); // Red = 0
        cv::merge(channels, processed);
        auto t2 = std::chrono::high_resolution_clock::now();

        // --- 3. Показ ---
        cv::imshow("Original", frame);
        cv::imshow("Processed", processed);
        auto t3 = std::chrono::high_resolution_clock::now();

        // Замер времени (в секундах)
        double capture_time = std::chrono::duration<double>(t1 - t0).count();
        double process_time = std::chrono::duration<double>(t2 - t1).count();
        double show_time    = std::chrono::duration<double>(t3 - t2).count();

        total_capture += capture_time;
        total_process += process_time;
        total_show    += show_time;

        frameCount++;

        // Выход по Esc (но не учитываем в замерах)
        if (cv::waitKey(1) == 27) break;
    }

    auto wall_end = std::chrono::high_resolution_clock::now();
    double wall_time = std::chrono::duration<double>(wall_end - wall_start).count();

    double total_cpu_time = total_capture + total_process + total_show;
    double fps = frameCount / wall_time;

    // Доли в процентах от общего CPU-времени
    double pct_capture = (total_capture / total_cpu_time) * 100.0;
    double pct_process = (total_process / total_cpu_time) * 100.0;
    double pct_show    = (total_show    / total_cpu_time) * 100.0;

    // Вывод результатов
    std::cout << "Обработано кадров: " << frameCount << std::endl;
    std::cout << "Общее время работы: " << wall_time << " сек" << std::endl;
    std::cout << "Средний FPS: " << fps << std::endl;
    std::cout << "  Захват кадра:   " << total_capture << " сек (" << pct_capture << "%)\n";
    std::cout << "  Преобразование: " << total_process << " сек (" << pct_process << "%)\n";
    std::cout << "  Показ:          " << total_show    << " сек (" << pct_show    << "%)\n";

    cap.release();
    cv::destroyAllWindows();
    return 0;
}