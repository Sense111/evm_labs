cmake_minimum_required(VERSION 3.29)
project(lab5)

set(CMAKE_CXX_STANDARD 20)

# Путь к OpenCV (папка, где находится OpenCVConfig.cmake)
set(OpenCV_DIR "Folder")

# Найти OpenCV
find_package(OpenCV REQUIRED)

# Создать исполняемый файл
add_executable(lab5 main.cpp
        main.cpp
        main.cpp)

# Линковка с OpenCV
target_link_libraries(lab5 ${OpenCV_LIBS})

# Пути для include (CLion их подхватит для подсветки)
include_directories(${OpenCV_INCLUDE_DIRS})
