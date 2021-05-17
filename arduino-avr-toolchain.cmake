#this file must be included as toolchain-file via command-line
#or by using set(CMAKE_TOOLCHAIN_FILE ArduinoCmakeBuilder/arduino-avr-toolchain.cmake) as first line in your CmakeLists.txt

#custom AVR_TOOLCHAIN_SEARCH_PATH may be provided at cmake commandline, it will be probed first
if(AVR_TOOLCHAIN_SEARCH_PATH)
    file(TO_CMAKE_PATH "${AVR_TOOLCHAIN_SEARCH_PATH}" CM_AVR_TOOLCHAIN_SEARCH_PATH)
    message(STATUS "Trying avr-toolchain search path at ${CM_AVR_TOOLCHAIN_SEARCH_PATH}")
endif()

#custom AVRDUDE_SEARCH_PATH may be provided at cmake commandline, it will be probed first
if(AVRDUDE_SEARCH_PATH)
    file(TO_CMAKE_PATH "${AVRDUDE_SEARCH_PATH}" CM_AVRDUDE_SEARCH_PATH)
    message(STATUS "Trying custom avrdude search path at ${CM_AVRDUDE_SEARCH_PATH}")
endif()

#helper functions for AVR toolchain probing, please do not invoke it manually
function(probe_arduino_avr_compiler PROBEPATH)
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

        message(STATUS "Found AVR toolchain at ${AVR_TOOLCHAIN_PATH}")
endfunction(probe_arduino_avr_compiler)

#helper function for avrdude utility probing, please do not invoke it manually
function(probe_arduino_avrdude PROBEPATH)
        if(NOT EXISTS ${PROBEPATH})
           message(STATUS "Directory ${PROBEPATH} does not exist, skipping")
           return()
        endif()

        message(STATUS "Searching for AVRDUDE utility at ${PROBEPATH}")
        unset(AVRDUDE_BIN CACHE)
        unset(AVRDUDE_CFG CACHE)

        find_program(AVRDUDE_BIN avrdude PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_file(AVRDUDE_CFG avrdude.conf PATHS "${PROBEPATH}/etc" NO_DEFAULT_PATH)

        foreach(probe IN ITEMS AVRDUDE_BIN AVRDUDE_CFG)
            if(("${${probe}}" STREQUAL "${probe}-NOTFOUND") OR ("${${probe}}" STREQUAL ""))
                message(STATUS "${probe} not found")
                return()
            endif()
        endforeach()

        set(AVRDUDE_PATH "${PROBEPATH}" CACHE INTERNAL "AVRDUDE utility autodetected path")
        set(AVRDUDE_BIN ${AVRDUDE_BIN} CACHE INTERNAL "AVRDUDE_BIN")
        set(AVRDUDE_CFG ${AVRDUDE_CFG} CACHE INTERNAL "AVRDUDE_CFG")

        message(STATUS "Found AVRDUDE utility at ${AVRDUDE_PATH}")
endfunction()

#define search directories based on OS
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
    file(GLOB AVRDUDE_TEST_DIRS
        ${CM_AVRDUDE_SEARCH_PATH}
        ${ENV_LOCALAPPDATA}/Arduino*/packages/arduino/tools/avrdude/*
        ${ENV_PROGRAMFILES}/Arduino/hardware/tools/avr
        ${ENV_PROGRAMFILES_X86}/Arduino/hardware/tools/avr)
elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
    file(TO_CMAKE_PATH "$ENV{HOME}" ENV_HOME)
    file(GLOB AVR_TEST_DIRS
        ${CM_AVR_TOOLCHAIN_SEARCH_PATH}
        ${ENV_HOME}/.arduino*/packages/arduino/tools/avr-gcc/*
        ${ENV_HOME}/arduino-*/hardware/tools/avr)
    file(GLOB AVRDUDE_TEST_DIRS
        ${CM_AVRDUDE_SEARCH_PATH}
        ${ENV_HOME}/.arduino*/packages/arduino/tools/avrdude/*
        ${ENV_HOME}/arduino-*/hardware/tools/avr)
else()
  message(FATAL_ERROR "This platform is not supported!")
endif ()

#search for AVR toolchain
foreach (avr_test_dir ${AVR_TEST_DIRS})
    if(NOT AVR_TOOLCHAIN_PATH)
        probe_arduino_avr_compiler ("${avr_test_dir}")
    endif()
endforeach ()

if(NOT AVR_TOOLCHAIN_PATH)
    message(FATAL_ERROR "Failed to detect valid AVR toolchain directory")
endif()

#search for avrdude utility
foreach (avrdude_test_dir ${AVRDUDE_TEST_DIRS})
    if(NOT AVRDUDE_PATH)
        probe_arduino_avrdude ("${avrdude_test_dir}")
    endif()
endforeach ()

if(NOT AVRDUDE_PATH)
    message(FATAL_ERROR "Failed to detect valid AVRDUDE utility")
endif()
