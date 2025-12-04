# Cargokit CMake integration for Flutter Rust Bridge
#
# This file provides the apply_cargokit function that builds Rust code
# and integrates it with the Flutter plugin build system.

function(apply_cargokit target manifest_dir crate_name)
    # Find the Rust toolchain
    find_program(CARGO cargo REQUIRED)
    find_program(RUSTC rustc REQUIRED)

    # Determine build type
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(CARGO_BUILD_TYPE "debug")
        set(CARGO_BUILD_FLAG "")
    else()
        set(CARGO_BUILD_TYPE "release")
        set(CARGO_BUILD_FLAG "--release")
    endif()

    # Determine target triple
    if(WIN32)
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(RUST_TARGET "x86_64-pc-windows-msvc")
        else()
            set(RUST_TARGET "i686-pc-windows-msvc")
        endif()
    endif()

    # Set up paths - use the native/ directory for the actual Rust crate
    set(RUST_MANIFEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../native")
    set(RUST_TARGET_DIR "${RUST_MANIFEST_DIR}/target")
    set(RUST_LIB_DIR "${RUST_TARGET_DIR}/${RUST_TARGET}/${CARGO_BUILD_TYPE}")
    set(RUST_LIB_FILE "${RUST_LIB_DIR}/${crate_name}.dll")

    # Custom command to build the Rust library
    add_custom_command(
        OUTPUT "${RUST_LIB_FILE}"
        COMMAND ${CMAKE_COMMAND} -E env "CARGO_TARGET_DIR=${RUST_TARGET_DIR}"
                ${CARGO} build ${CARGO_BUILD_FLAG} --target ${RUST_TARGET}
        WORKING_DIRECTORY "${RUST_MANIFEST_DIR}"
        COMMENT "Building Rust library ${crate_name}"
        VERBATIM
    )

    # Custom target for the Rust build
    add_custom_target(${target}_cargo_build
        DEPENDS "${RUST_LIB_FILE}"
    )

    # Create an imported library target
    add_library(${target} SHARED IMPORTED GLOBAL)
    add_dependencies(${target} ${target}_cargo_build)
    set_target_properties(${target} PROPERTIES
        IMPORTED_LOCATION "${RUST_LIB_FILE}"
        IMPORTED_IMPLIB "${RUST_LIB_DIR}/${crate_name}.dll.lib"
    )

    # Set the bundled libraries for Flutter to pick up
    set(${target}_bundled_libraries "${RUST_LIB_FILE}" PARENT_SCOPE)
endfunction()
