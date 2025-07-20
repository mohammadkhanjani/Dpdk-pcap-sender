cmake_minimum_required(VERSION 3.10)

# Enable optimizations and required instruction sets
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -march=native -mtune=native")

# Find DPDK package
find_package(PkgConfig REQUIRED)
pkg_check_modules(DPDK REQUIRED libdpdk)

add_executable(${CMAKE_PROJECT_NAME}
    config.c
    init.c
    runtime.c
    main.c
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    ${DPDK_INCLUDE_DIRS}
)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
    ${DPDK_LIBRARIES}
    pcap
    pthread
    hptl
    numa
)

if(DPDK_CFLAGS_OTHER)
    target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE ${DPDK_CFLAGS_OTHER})
endif()
