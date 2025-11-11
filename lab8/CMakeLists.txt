cmake_minimum_required(VERSION 4.0)
project(lab8)

set(CMAKE_CXX_STANDARD 20)

set(CMAKE_CXX_FLAGS_DEBUG "-g -O1")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O1")


add_executable(lab8 main.cpp)
