cmake_minimum_required(VERSION 3.22)
project(vina-gpu LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_STATIC_RUNTIME ON)
set(Boost_NO_WARN_NEW_VERSIONS ON)

find_package(Boost REQUIRED COMPONENTS program_options system filesystem thread serialization)
find_package(OpenCL REQUIRED)

FILE(GLOB LIB_SRCS ./lib/*.cpp)
add_executable(Vina-GPU ./main/main.cpp ${LIB_SRCS} ./OpenCL/src/wrapcl.cpp)

target_include_directories(Vina-GPU 
    PUBLIC .
    PUBLIC ./lib
    PUBLIC ./OpenCL/inc
    PUBLIC ${Boost_INCLUDE_DIRS})

target_link_libraries(Vina-GPU ${Boost_LIBRARIES} ${OpenCL_LIBRARIES})

set_property(TARGET Vina-GPU PROPERTY
  MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

target_link_options(Vina-GPU PUBLIC "/STACK:10000000")

SET(BUILD_KERNEL_FROM_SOURCE false CACHE BOOL "Build kernel from source")

if (BUILD_KERNEL_FROM_SOURCE)
    add_compile_definitions(BUILD_KERNEL_FROM_SOURCE)
endif()

add_compile_definitions(CL_TARGET_OPENCL_VERSION=120)
add_compile_definitions(AMD_PLATFORM)
add_compile_definitions(OPENCL_1_2)
