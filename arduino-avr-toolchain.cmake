cmake_minimum_required(VERSION 3.0)

function(probe_arduino_avr_compiler PROBEPATH)
    if(NOT AVR_TOOLCHAIN_PATH)
        if(NOT EXISTS ${PROBEPATH})
           message(STATUS "Directory ${PROBEPATH} does not exist, skipping")
           return()
        endif()
        message(STATUS "Searching for AVR toolchain at ${PROBEPATH}")
        unset(AVR_CXX CACHE)
        unset(AVR_C CACHE)
        unset(AVR_AR CACHE)
        unset(AVR_RANLIB CACHE)
        unset(AVR_STRIP CACHE)
        unset(AVR_OBJCOPY CACHE)
        unset(AVR_OBJDUMP CACHE)
        unset(AVR_SIZE CACHE)

        find_program(AVR_CXX avr-g++ PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_program(AVR_C avr-gcc PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_program(AVR_AR avr-gcc-ar PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_program(AVR_RANLIB avr-gcc-ranlib PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_program(AVR_STRIP avr-strip PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_program(AVR_OBJCOPY avr-objcopy PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_program(AVR_OBJDUMP avr-objdump PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_program(AVR_SIZE avr-size PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)

        foreach(avr_util IN ITEMS AVR_CXX AVR_C AVR_AR AVR_STRIP AVR_OBJCOPY AVR_OBJDUMP AVR_SIZE)
            if(("${${avr_util}}" STREQUAL "${avr_util}-NOTFOUND") OR ("${${avr_util}}" STREQUAL ""))
                message(STATUS "${avr_util} not found")
                return()
            endif()
        endforeach()

        set(AVR_TOOLCHAIN_PATH "${PROBEPATH}" CACHE INTERNAL "AVR toolchain autodetected path")
        set(AVR_CXX ${AVR_CXX} CACHE INTERNAL "AVR_CXX")
        set(AVR_C ${AVR_C} CACHE INTERNAL "AVR_C")
        set(AVR_AR ${AVR_AR} CACHE INTERNAL "AVR_AR")
        set(AVR_RANLIB ${AVR_RANLIB} CACHE INTERNAL "AVR_RANLIB")
        set(AVR_STRIP ${AVR_STRIP} CACHE INTERNAL "AVR_STRIP")
        set(AVR_OBJCOPY ${AVR_OBJCOPY} CACHE INTERNAL "AVR_OBJCOPY")
        set(AVR_OBJDUMP ${AVR_OBJDUMP} CACHE INTERNAL "AVR_OBJDUMP")
        set(AVR_SIZE ${AVR_SIZE} CACHE INTERNAL "AVR_SIZE")

        set(CMAKE_SYSTEM_NAME "Generic" CACHE INTERNAL "CMAKE_SYSTEM_NAME")
        set(CMAKE_CXX_COMPILER ${AVR_CXX} CACHE INTERNAL "CMAKE_CXX_COMPILER")
        set(CMAKE_C_COMPILER ${AVR_C} CACHE INTERNAL "CMAKE_C_COMPILER")
        set(CMAKE_AR ${AVR_AR} CACHE INTERNAL "CMAKE_AR")
        set(CMAKE_RANLIB ${AVR_RANLIB} CACHE INTERNAL "CMAKE_RANLIB")
        set(CMAKE_ASM_COMPILER ${AVR_C} CACHE INTERNAL "CMAKE_ASM_COMPILER")
        set(CMAKE_PREFIX_PATH ${PROBEPATH} CACHE INTERNAL "CMAKE_PREFIX_PATH")
        set(CMAKE_LINKER ${AVR_C} CACHE INTERNAL "CMAKE_LINKER")
        set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>" CACHE INTERNAL "CMAKE_C_LINK_EXECUTABLE")
        set(CMAKE_CXX_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>" CACHE INTERNAL "CMAKE_CXX_LINK_EXECUTABLE")
    endif()
endfunction(probe_arduino_avr_compiler)

set(AVR_TOOLCHAIN_SEARCH_PATH "" CACHE PATH "Custom AVR toolchain search path, will be probed first")
if(NOT ${AVR_TOOLCHAIN_SEARCH_PATH} STREQUAL "")
    file(TO_CMAKE_PATH "${AVR_TOOLCHAIN_SEARCH_PATH}" CM_AVR_TOOLCHAIN_SEARCH_PATH)
    message(STATUS "Will try custom search path at ${CM_AVR_TOOLCHAIN_SEARCH_PATH}")
    unset(AVR_TOOLCHAIN_PATH CACHE)
endif()

if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    file(TO_CMAKE_PATH "$ENV{LOCALAPPDATA}" ENV_LOCALAPPDATA)
    set(PROGRAMFILES_X86 "ProgramFiles(x86)")
    file(TO_CMAKE_PATH "$ENV{${PROGRAMFILES_X86}}" ENV_PROGRAMFILES_X86)
    file(TO_CMAKE_PATH "$ENV{ProgramFiles}" ENV_PROGRAMFILES)
    file(GLOB AVR_TEST_DIRS
        ${CM_AVR_TOOLCHAIN_SEARCH_PATH}
        ${ENV_LOCALAPPDATA}/Arduino*/packages/arduino/tools/avr-gcc/*
        ${ENV_PROGRAMFILES}/Arduino/hardware/tools/avr
        ${ENV_PROGRAMFILES_X86}/Arduino/hardware/tools/avr)
elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
  message(FATAL_ERROR "TODO")
else()
  message(FATAL_ERROR "This platform is not supported!")
endif ()

foreach (avr_test_dir ${AVR_TEST_DIRS})
    probe_arduino_avr_compiler ("${avr_test_dir}")
endforeach ()

if(NOT AVR_TOOLCHAIN_PATH)
    message(FATAL_ERROR "Failed to detect valid AVR toolchain directory")
endif()

message(STATUS "Using AVR toolchain at ${AVR_TOOLCHAIN_PATH}")

set(ARDUINO_MCU "atmega328p" CACHE STRING "MCU model, used by compiler")
set(ARDUINO_F_CPU "16000000" CACHE STRING "Target clock speed")

set(ARDUINO_CXX_FLAGS "-g -Os -Wall -Wextra -std=gnu++11 -fpermissive -fno-exceptions -ffunction-sections -fdata-sections -fno-threadsafe-statics -MMD -flto" CACHE STRING "Arduino AVR C++ flags (from arduino IDE 1.8.5)")
set(ARDUINO_CXX_FLAGS_FULL "${ARDUINO_CXX_FLAGS} -mmcu=${ARDUINO_MCU} -DF_CPU=${ARDUINO_F_CPU} -DARDUINO_ARCH_AVR" CACHE INTERNAL "ARDUINO_CXX_FLAGS_FULL")

set(ARDUINO_C_FLAGS "-g -Os -Wall -Wextra -std=gnu11 -ffunction-sections -fdata-sections -MMD -flto -fno-fat-lto-objects" CACHE STRING "Arduino AVR C flags (from arduino IDE 1.8.5)")
set(ARDUINO_C_FLAGS_FULL "${ARDUINO_C_FLAGS} -mmcu=${ARDUINO_MCU} -DF_CPU=${ARDUINO_F_CPU} -DARDUINO_ARCH_AVR" CACHE INTERNAL "ARDUINO_C_FLAGS_FULL")

set(ARDUINO_ASM_FLAGS "-x assembler-with-cpp -g -Os -Wall -Wextra -MMD -flto -fno-fat-lto-objects" CACHE STRING "Arduino AVR ASM flags")
set(ARDUINO_ASM_FLAGS_FULL "${ARDUINO_ASM_FLAGS} -mmcu=${ARDUINO_MCU} -DF_CPU=${ARDUINO_F_CPU} -DARDUINO_ARCH_AVR" CACHE INTERNAL "ARDUINO_ASM_FLAGS_FULL")

set(ARDUINO_EXE_LINKER_FLAGS "-Wall -Wextra -Os -g -flto -fuse-linker-plugin -Wl,--gc-sections" CACHE STRING "Arduino AVR GCC-linker flags")
set(ARDUINO_EXE_LINKER_FLAGS_FULL "${ARDUINO_EXE_LINKER_FLAGS} -mmcu=${ARDUINO_MCU}" CACHE INTERNAL "ARDUINO_EXE_LINKER_FLAGS_FULL")

set(ARDUINO_ARCH "avr" CACHE INTERNAL "ARDUINO_ARCH")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/build.${ARDUINO_ARCH}" CACHE INTERNAL "CMAKE_ARCHIVE_OUTPUT_DIRECTORY")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/build.${ARDUINO_ARCH}" CACHE INTERNAL "CMAKE_RUNTIME_OUTPUT_DIRECTORY")
