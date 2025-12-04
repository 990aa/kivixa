# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "rust_lib_kivixa")
project(${PROJECT_NAME} LANGUAGES CXX)

# Invoke cargokit to build the native Rust library
include("../cargokit/cmake/cargokit.cmake")
apply_cargokit(${PROJECT_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/../.." "kivixa_native")
