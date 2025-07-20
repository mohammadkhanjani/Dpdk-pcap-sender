cmake_minimum_required(VERSION 3.10)
project(dpdk_pcap_sender)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_subdirectory(hptimelib)
include_directories(hptimelib)

add_subdirectory(src)
