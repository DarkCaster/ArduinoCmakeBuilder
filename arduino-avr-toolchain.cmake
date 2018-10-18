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

        message(STATUS "Found AVR toolchain at ${AVR_TOOLCHAIN_PATH}")
    endif()
endfunction(probe_arduino_avr_compiler)

function(probe_arduino_avrdude PROBEPATH)
    if(NOT AVRDUDE_PATH)
        if(NOT EXISTS ${PROBEPATH})
           message(STATUS "Directory ${PROBEPATH} does not exist, skipping")
           return()
        endif()

        message(STATUS "Searching for AVRDUDE utility at ${PROBEPATH}")
        unset(AVRDUDE_BIN CACHE)
        unset(AVRDUDE_CFG CACHE)

        find_program(AVRDUDE_BIN avrdude PATHS "${PROBEPATH}/bin" NO_DEFAULT_PATH)
        find_program(AVRDUDE_CFG avrdude.conf PATHS "${PROBEPATH}/etc" NO_DEFAULT_PATH)

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
    endif()
endfunction()

set(AVR_TOOLCHAIN_SEARCH_PATH "" CACHE PATH "Custom AVR toolchain search path, will be probed first")
if(NOT "${AVR_TOOLCHAIN_SEARCH_PATH}" STREQUAL "")
    file(TO_CMAKE_PATH "${AVR_TOOLCHAIN_SEARCH_PATH}" CM_AVR_TOOLCHAIN_SEARCH_PATH)
    if(NOT "${AVR_TOOLCHAIN_SEARCH_PATH}" STREQUAL "${AVR_TOOLCHAIN_SEARCH_PATH_PREV}") #if AVR_TOOLCHAIN_SEARCH_PATH was changed
      message(STATUS "Will try custom avr-toolchain search path at ${CM_AVR_TOOLCHAIN_SEARCH_PATH}")
      unset(AVR_TOOLCHAIN_PATH CACHE)
      set(AVR_TOOLCHAIN_SEARCH_PATH_PREV "${AVR_TOOLCHAIN_SEARCH_PATH}" CACHE INTERNAL "AVR_TOOLCHAIN_SEARCH_PATH_PREV")
    endif()
elseif(NOT "${AVR_TOOLCHAIN_SEARCH_PATH_PREV}" STREQUAL "") #if AVR_TOOLCHAIN_SEARCH_PATH was unset after being used in previous run
    message(STATUS "Removing custom avr-toolchain search path from evaluation")
    unset(AVR_TOOLCHAIN_SEARCH_PATH_PREV CACHE)
    unset(AVR_TOOLCHAIN_PATH CACHE)
endif()

set(AVRDUDE_SEARCH_PATH "" CACHE PATH "Custom AVRDUDE search path, will be probed first")
if(NOT ${AVRDUDE_SEARCH_PATH} STREQUAL "")
    file(TO_CMAKE_PATH "${AVRDUDE_SEARCH_PATH}" CM_AVRDUDE_SEARCH_PATH)
    if(NOT "${AVRDUDE_SEARCH_PATH}" STREQUAL "${AVRDUDE_SEARCH_PATH_PREV}") #if AVR_TOOLCHAIN_SEARCH_PATH was changed
      message(STATUS "Will try custom avrdude search path at ${CM_AVRDUDE_SEARCH_PATH}")
      unset(AVRDUDE_PATH CACHE)
      set(AVRDUDE_SEARCH_PATH_PREV "${AVRDUDE_SEARCH_PATH}" CACHE INTERNAL "AVRDUDE_SEARCH_PATH_PREV")
    endif()
elseif(NOT "${AVRDUDE_SEARCH_PATH_PREV}" STREQUAL "") #if AVRDUDE_SEARCH_PATH was unset after being used in previous run
    message(STATUS "Removing custom avrdude search path from evaluation")
    unset(AVRDUDE_SEARCH_PATH_PREV CACHE)
    unset(AVRDUDE_PATH CACHE)
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

foreach (avr_test_dir ${AVR_TEST_DIRS})
    probe_arduino_avr_compiler ("${avr_test_dir}")
endforeach ()

if(NOT AVR_TOOLCHAIN_PATH)
    message(FATAL_ERROR "Failed to detect valid AVR toolchain directory")
endif()

foreach (avrdude_test_dir ${AVRDUDE_TEST_DIRS})
    probe_arduino_avrdude ("${avrdude_test_dir}")
endforeach ()

if(NOT AVRDUDE_PATH)
    message(FATAL_ERROR "Failed to detect valid AVRDUDE utility")
endif()

set(ARDUINO_MCU "atmega328p" CACHE STRING "MCU model, used by compiler")
set(ARDUINO_F_CPU "16000000L" CACHE STRING "Target clock speed")

set(ARDUINO_CXX_FLAGS "-g -Os -Wall -Wextra -std=gnu++11 -fpermissive -fno-exceptions -ffunction-sections -fdata-sections -fno-threadsafe-statics -flto" CACHE STRING "Arduino AVR C++ flags (from arduino IDE 1.8.5)")
set(ARDUINO_C_FLAGS "-g -Os -Wall -Wextra -std=gnu11 -ffunction-sections -fdata-sections -flto -fno-fat-lto-objects" CACHE STRING "Arduino AVR C flags (from arduino IDE 1.8.5)")
set(ARDUINO_ASM_FLAGS "-x assembler-with-cpp -g -Os -Wall -Wextra -flto -fno-fat-lto-objects" CACHE STRING "Arduino AVR ASM flags")
set(ARDUINO_EXE_LINKER_FLAGS "-Wall -Wextra -Os -g -flto -fuse-linker-plugin -Wl,--gc-sections" CACHE STRING "Arduino AVR GCC-linker flags")

# add default compiler definitions

set(CMAKE_CXX_FLAGS "-x c++ ${ARDUINO_CXX_FLAGS} -mmcu=${ARDUINO_MCU}")
set(CMAKE_CXX_FLAGS_RELEASE "")
set(CMAKE_CXX_FLAGS_MINSIZEREL "")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "")
set(CMAKE_CXX_FLAGS_DEBUG "")
set(CMAKE_C_FLAGS "-x c ${ARDUINO_C_FLAGS} -mmcu=${ARDUINO_MCU}")
set(CMAKE_C_FLAGS_RELEASE "")
set(CMAKE_C_FLAGS_MINSIZEREL "")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "")
set(CMAKE_C_FLAGS_DEBUG "")
set(CMAKE_ASM_FLAGS "${ARDUINO_ASM_FLAGS} -mmcu=${ARDUINO_MCU}")
set(CMAKE_EXE_LINKER_FLAGS "${ARDUINO_EXE_LINKER_FLAGS} -mmcu=${ARDUINO_MCU}")

if(NOT ARDUINO_AVR_DEFINITIONS_SET)
    add_definitions("-D__AVR__")
    add_definitions("-DARDUINO_ARCH_AVR")
    add_definitions("-DF_CPU=${ARDUINO_F_CPU}")
    set(ARDUINO_AVR_DEFINITIONS_SET TRUE)
endif()

set(ARDUINO_ARCH "avr" CACHE INTERNAL "ARDUINO_ARCH")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/build.${ARDUINO_ARCH}" CACHE INTERNAL "CMAKE_ARCHIVE_OUTPUT_DIRECTORY")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/build.${ARDUINO_ARCH}" CACHE INTERNAL "CMAKE_RUNTIME_OUTPUT_DIRECTORY")

function(add_arduino_post_target BASE_TARGET)
    set(EXTRA_CLEAN_FILES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}.hex ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}.eep ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}.lst)
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${EXTRA_CLEAN_FILES}")
    add_custom_command(OUTPUT ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}.hex
        COMMAND ${AVR_STRIP} "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}"
        COMMAND ${AVR_OBJCOPY} -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0 "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}.eep"
        COMMAND ${AVR_OBJCOPY} -O ihex -R .eeprom "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}.hex"
        COMMAND ${AVR_SIZE} --mcu=${MCU} -C --format=avr "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}"
        DEPENDS ${BASE_TARGET})
    add_custom_target(${BASE_TARGET}-post DEPENDS ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}.hex)
endfunction()

set(ARDUINO_AVRDUDE_PORT "COM1" CACHE STRING "avrdude -P param")
set(ARDUINO_AVRDUDE_BAUD "19200" CACHE STRING "avrdude -b param")
set(ARDUINO_AVRDUDE_PROTO "arduino" CACHE STRING "avrdude -c param")
set(ARDUINO_AVRDUDE_MCU ${ARDUINO_MCU} CACHE STRING "avrdude -p param")
set(ARDUINO_AVRDUDE_EXTRACMD "-v;-D" CACHE STRING "avrdude extra parameters")

function(add_arduino_upload_target BASE_TARGET)
    add_custom_command(OUTPUT ${BASE_TARGET}.upload
        COMMAND ${AVRDUDE_BIN} -C\"${AVRDUDE_CFG}\" -P${ARDUINO_AVRDUDE_PORT} -b${ARDUINO_AVRDUDE_BAUD} -c${ARDUINO_AVRDUDE_PROTO} -p${ARDUINO_AVRDUDE_MCU} ${ARDUINO_AVRDUDE_EXTRACMD} -Uflash:w:\"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}\".hex:i
        DEPENDS ${BASE_TARGET}-post)
    add_custom_target(${BASE_TARGET}-upload DEPENDS ${BASE_TARGET}.upload)
endfunction()

function(gcc_find_default_includes COMPILER_BIN COMPILER_FLAGS RESULT_CACHE)
    file(WRITE "${CMAKE_BINARY_DIR}/include_test" "\n")
    separate_arguments(FLAGS UNIX_COMMAND ${COMPILER_FLAGS})
    execute_process(COMMAND ${COMPILER_BIN} ${FLAGS} -v -E -dD include_test
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR} OUTPUT_QUIET ERROR_VARIABLE COMPILER_OUTPUT)
    file(REMOVE "${CMAKE_BINARY_DIR}/include_test")
    if ("${COMPILER_OUTPUT}" MATCHES "> search starts here[^\n]+\n *(.+) *\n *End of (search) list")
        set(RAW_PATH_LIST ${CMAKE_MATCH_1})
        STRING(REGEX REPLACE ";" "\\\\;" RAW_PATH_LIST "${RAW_PATH_LIST}")
        STRING(REGEX REPLACE "\n" ";" RAW_PATH_LIST "${RAW_PATH_LIST}")
        foreach(EVAL_PATH IN LISTS RAW_PATH_LIST)
            string(STRIP "${EVAL_PATH}" EVAL_PATH)
            file(TO_CMAKE_PATH "${EVAL_PATH}" EVAL_PATH)
            get_filename_component(EVAL_PATH "${EVAL_PATH}" REALPATH)
            if(NOT EXISTS ${EVAL_PATH})
                message(WARNING "Failed to process include directory ${EVAL_PATH}")
            else()
                list(APPEND FINAL_PATH_LIST ${EVAL_PATH})
            endif()
        endforeach()
        set(${RESULT_CACHE} ${FINAL_PATH_LIST} CACHE INTERNAL "${RESULT_CACHE}")
    else()
        message(FATAL_ERROR "Failed to detect default include directories!")
    endif()
endfunction()

if(NOT AVR_C_DEFAULT_INCLUDES)
    message(STATUS "Detecting default include dirs for C language")
    gcc_find_default_includes("${AVR_C}" "${CMAKE_C_FLAGS}" "AVR_C_DEFAULT_INCLUDES")
endif()

if(NOT AVR_CXX_DEFAULT_INCLUDES)
    message(STATUS "Detecting default include dirs for C++ language")
    gcc_find_default_includes("${AVR_CXX}" "${CMAKE_CXX_FLAGS}" "AVR_CXX_DEFAULT_INCLUDES")
endif()

include_directories(SYSTEM "${AVR_C_DEFAULT_INCLUDES}")
include_directories(SYSTEM "${AVR_CXX_DEFAULT_INCLUDES}")

function(gcc_find_extra_defines COMPILER_BIN COMPILER_FLAGS RESULT_CACHE)

    file(WRITE "${CMAKE_BINARY_DIR}/define_test" "\n")
    separate_arguments(FLAGS UNIX_COMMAND ${COMPILER_FLAGS})
    get_property(CURRENT_DEFINES_RAW DIRECTORY PROPERTY "COMPILE_DEFINITIONS")
    foreach(EVAL_DEFINE IN LISTS CURRENT_DEFINES_RAW)
        list(APPEND CURRENT_DEFINES "-D${EVAL_DEFINE}")
    endforeach()
    execute_process(COMMAND ${COMPILER_BIN} ${FLAGS} ${CURRENT_DEFINES} -E -dD define_test
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR} OUTPUT_VARIABLE COMPILER_OUTPUT ERROR_QUIET)
    file(REMOVE "${CMAKE_BINARY_DIR}/define_test")
    if ("${COMPILER_OUTPUT}" MATCHES "# 1 \"<command-line>\"\n(.+)\n# 1 \"define_test\"")
        set(RAW_DEFINE_LIST ${CMAKE_MATCH_1})
        STRING(REGEX REPLACE ";" "\\\\;" RAW_DEFINE_LIST "${RAW_DEFINE_LIST}")
        STRING(REGEX REPLACE "\n" ";" RAW_DEFINE_LIST "${RAW_DEFINE_LIST}")
        foreach(EVAL_DEFINE IN LISTS RAW_DEFINE_LIST)
            if ("${EVAL_DEFINE}" MATCHES "^(#define) ([^ ]+) (.*)$")
                if("${CMAKE_MATCH_3}" STREQUAL "1")
                    set(FINAL_EVAL_DEFINE "-D${CMAKE_MATCH_2}")
                else()
                    set(FINAL_EVAL_DEFINE "-D${CMAKE_MATCH_2}=${CMAKE_MATCH_3}")
                endif()
                list(APPEND FINAL_DEFINES_LIST ${FINAL_EVAL_DEFINE})
            else()
                message(WARNING "Incorrect extra define string from compiler output: ${EVAL_DEFINE}")
            endif()
        endforeach()
        set(${RESULT_CACHE} ${FINAL_DEFINES_LIST} CACHE INTERNAL "${RESULT_CACHE}")
    else()
        message(FATAL_ERROR "Failed to detect default include directories!")
    endif()
endfunction()

# detect compiler's extra built-in defines that appears after adding our custom definition flags and compiler options for selected MCU and other stuff
if(NOT AVR_C_EXTRA_DEFINES)
    message(STATUS "Detecting extra defines for C language")
    gcc_find_extra_defines("${AVR_C}" "${CMAKE_C_FLAGS}" "AVR_C_EXTRA_DEFINES")
endif()

if(NOT AVR_CXX_EXTRA_DEFINES)
    message(STATUS "Detecting extra defines for C++ language")
    gcc_find_extra_defines("${AVR_CXX}" "${CMAKE_CXX_FLAGS}" "AVR_CXX_EXTRA_DEFINES")
endif()

function(gcc_merge_defines DEFINES_LIST)
    get_property(CURRENT_DEFINES_RAW DIRECTORY PROPERTY "COMPILE_DEFINITIONS")
    foreach(EVAL_DEFINE IN LISTS CURRENT_DEFINES_RAW)
        list(APPEND CURRENT_DEFINES "-D${EVAL_DEFINE}")
    endforeach()
    foreach(EVAL_DEFINE IN LISTS DEFINES_LIST)
        list(FIND CURRENT_DEFINES "${EVAL_DEFINE}" CURRENT_DEFINES_INDEX)
        if(NOT "${CURRENT_DEFINES_INDEX}" GREATER "-1")
            #message(STATUS "Adding extra definition: ${EVAL_DEFINE}")
            add_definitions("${EVAL_DEFINE}")
        endif()
    endforeach()
endfunction()

#merge extra defines with current definitions
#this is needed for QT-Creator for static-analisys to work correctly with arduino core sources
if(NOT ARDUINO_AVR_EXTRA_DEFINITIONS_SET)
    gcc_merge_defines("${AVR_C_EXTRA_DEFINES}")
    gcc_merge_defines("${AVR_CXX_EXTRA_DEFINES}")
    set(ARDUINO_AVR_EXTRA_DEFINITIONS_SET TRUE)
endif()
