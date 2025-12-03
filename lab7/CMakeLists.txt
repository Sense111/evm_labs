cmake_minimum_required(VERSION 4.0)
project(lab7)

set(CMAKE_CXX_STANDARD 20)

add_executable(lab7 main.cpp
        helpers.cpp
        scalar_inverter.cpp
        avx_inverter.cpp
        blas_inverter.cpp)
target_compile_options(lab7 PUBLIC "-march=native")
target_link_libraries(lab7 PRIVATE openblas)
