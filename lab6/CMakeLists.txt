cmake_minimum_required(VERSION 4.0)
project(untitled)

set(CMAKE_CXX_STANDARD 20)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)

add_executable(untitled main.cpp)

target_include_directories(untitled PRIVATE ${LIBUSB_INCLUDE_DIRS})
target_link_libraries(untitled PRIVATE ${LIBUSB_LIBRARIES})