find_package(Threads REQUIRED)

add_library(mtmd
    mtmd.cpp
    mtmd-audio.cpp
    mtmd-helper.cpp
    clip.cpp
    mtmd.h
    mtmd-audio.h
    mtmd-helper.h
    clip.h
    clip-impl.h
)

target_link_libraries(mtmd PUBLIC ggml llama)
target_link_libraries(mtmd PRIVATE Threads::Threads)
target_include_directories(mtmd PUBLIC .)
target_include_directories(mtmd PRIVATE ../.. ../../vendor)
target_compile_features(mtmd PRIVATE cxx_std_17)

if (BUILD_SHARED_LIBS)
    set_target_properties(mtmd PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_compile_definitions(mtmd PRIVATE LLAMA_BUILD)
    target_compile_definitions(mtmd PUBLIC LLAMA_SHARED)
endif()

set(MTMD_PUBLIC_HEADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/mtmd.h
    ${CMAKE_CURRENT_SOURCE_DIR}/mtmd-helper.h
)

set_target_properties(mtmd PROPERTIES PUBLIC_HEADER "${MTMD_PUBLIC_HEADERS}")

install(TARGETS mtmd
    LIBRARY
    ARCHIVE
    RUNTIME
    PUBLIC_HEADER
)
