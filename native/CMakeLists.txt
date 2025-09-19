cmake_minimum_required(VERSION 3.15)

# Project configuration
project(simple_tuner_audio)

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Platform-specific configurations
if(ANDROID)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined")
elseif(iOS)
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
endif()

# Include directories
include_directories(include)

# Source files
set(SOURCES
    src/audio_processor.cpp
)

# Create shared library
add_library(simple_tuner_audio SHARED ${SOURCES})

# Compiler-specific options
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(simple_tuner_audio PRIVATE 
        -Wall 
        -Wextra 
        -O3
        -ffast-math
    )
endif()

# Platform-specific linking
if(ANDROID)
    find_library(log-lib log)
    target_link_libraries(simple_tuner_audio ${log-lib})
elseif(APPLE)
    if(iOS)
        target_link_libraries(simple_tuner_audio "-framework AVFoundation")
    else()
        target_link_libraries(simple_tuner_audio "-framework CoreAudio" "-framework AudioUnit")
    endif()
elseif(WIN32)
    target_link_libraries(simple_tuner_audio winmm)
elseif(UNIX)
    # Linux - link with ALSA
    target_link_libraries(simple_tuner_audio asound)
endif()

# Threading support
find_package(Threads REQUIRED)
target_link_libraries(simple_tuner_audio Threads::Threads)

# Output directory
set_target_properties(simple_tuner_audio PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

# Install rules
install(TARGETS simple_tuner_audio
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)
