cmake_minimum_required(VERSION 4.0)
project(untitled1)

set(CMAKE_CXX_STANDARD 20)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)

add_executable(untitled1 main.cpp)

target_include_directories(untitled1 PRIVATE ${LIBUSB_INCLUDE_DIRS})
target_link_libraries(untitled1 PRIVATE ${LIBUSB_LIBRARIES})