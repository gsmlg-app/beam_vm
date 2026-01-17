# CMakeLists.txt for beam_vm_android Flutter plugin
# This plugin provides JNI bindings for the BEAM VM with bundled liberlang.a

cmake_minimum_required(VERSION 3.22.1)
project("beam_vm" LANGUAGES CXX)

# Find liberlang.a bundled within this package
# The library is located in android/src/main/jniLibs/{ABI}/
set(ERLANG_LIB_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/liberlang.a")

if(EXISTS "${ERLANG_LIB_PATH}")
    message(STATUS "Found bundled liberlang.a: ${ERLANG_LIB_PATH}")

    # Import liberlang as static library
    add_library(erlang STATIC IMPORTED)
    set_target_properties(erlang PROPERTIES
        IMPORTED_LOCATION "${ERLANG_LIB_PATH}"
    )
    set(HAVE_ERLANG TRUE)
else()
    message(WARNING "liberlang.a not found at: ${ERLANG_LIB_PATH}")
    message(WARNING "Binary not yet bundled - run CI workflow to download binaries")
    set(HAVE_ERLANG FALSE)
endif()

# Create the native library
add_library(beam_vm SHARED
    beam_vm_native.cpp
)

# Include directories
target_include_directories(beam_vm PRIVATE
    ${CMAKE_SOURCE_DIR}
)

# Link libraries
target_link_libraries(beam_vm
    android
    log
    z
    m
    dl
)

# Link erlang if available
if(HAVE_ERLANG)
    target_link_libraries(beam_vm erlang)
    target_compile_definitions(beam_vm PRIVATE HAVE_ERLANG=1)
endif()

# C++ standard
set_target_properties(beam_vm PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)
