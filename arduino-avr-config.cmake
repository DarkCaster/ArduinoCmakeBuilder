# this script will set various toolchain defines - both common and arduino-specific
# you may redefine default some params before including this script

# default params used for setting gcc flags, you may freely redefine it
set(ARDUINO_MCU "atmega328p" CACHE STRING "MCU model, used by compiler")
set(ARDUINO_F_CPU "16000000L" CACHE STRING "Target clock speed")

# default params used for setting avrdude utility flags, you may freely redefine it
# by default it is tuned for use optiboot bootloader
set(ARDUINO_AVRDUDE_PORT "COM1" CACHE STRING "avrdude -P param")
set(ARDUINO_AVRDUDE_BAUD "115200" CACHE STRING "avrdude -b param")
set(ARDUINO_AVRDUDE_PROTO "arduino" CACHE STRING "avrdude -c param")
set(ARDUINO_AVRDUDE_MCU ${ARDUINO_MCU} CACHE STRING "avrdude -p param")
set(ARDUINO_AVRDUDE_EXTRACMD "-v;-D" CACHE STRING "avrdude extra parameters")

# default base compiler flags, compatible with default avr arduino-core, you may redefine it with caution
set(ARDUINO_CXX_FLAGS "-g -Os -Wall -Wextra -std=gnu++11 -fpermissive -fno-exceptions -ffunction-sections -fdata-sections -fno-threadsafe-statics -Wno-error=narrowing -flto" CACHE STRING "Arduino AVR C++ flags (from arduino IDE 1.8.10)")
set(ARDUINO_C_FLAGS "-g -Os -Wall -Wextra -std=gnu11 -ffunction-sections -fdata-sections -Wno-error=narrowing -flto -fno-fat-lto-objects" CACHE STRING "Arduino AVR C flags (from arduino IDE 1.8.10)")
set(ARDUINO_ASM_FLAGS "-g -x assembler-with-cpp -flto" CACHE STRING "Arduino AVR ASM flags")
set(ARDUINO_EXE_LINKER_FLAGS "-Wall -Wextra -Os -g -flto -fuse-linker-plugin -Wl,--gc-sections,--relax" CACHE STRING "Arduino AVR GCC-linker flags")

# helper method for setting all needed compiler flags at once
function(set_avr_compiler_flags)
    message(STATUS "Setting AVR compiler flags")
    # remove old definitions (if cached)
    unset(CMAKE_CXX_FLAGS CACHE)
    unset(CMAKE_CXX_FLAGS_RELEASE CACHE)
    unset(CMAKE_CXX_FLAGS_MINSIZEREL CACHE)
    unset(CMAKE_CXX_FLAGS_RELWITHDEBINFO CACHE)
    unset(CMAKE_CXX_FLAGS_DEBUG CACHE)
    unset(CMAKE_C_FLAGS CACHE)
    unset(CMAKE_C_FLAGS_RELEASE CACHE)
    unset(CMAKE_C_FLAGS_MINSIZEREL CACHE)
    unset(CMAKE_C_FLAGS_RELWITHDEBINFO CACHE)
    unset(CMAKE_C_FLAGS_DEBUG CACHE)
    unset(CMAKE_ASM_FLAGS CACHE)
    unset(CMAKE_EXE_LINKER_FLAGS CACHE)
    # remove old definitions (regular variables at parent scope as precaution)
    unset(CMAKE_CXX_FLAGS PARENT_SCOPE)
    unset(CMAKE_CXX_FLAGS_RELEASE PARENT_SCOPE)
    unset(CMAKE_CXX_FLAGS_MINSIZEREL PARENT_SCOPE)
    unset(CMAKE_CXX_FLAGS_RELWITHDEBINFO PARENT_SCOPE)
    unset(CMAKE_CXX_FLAGS_DEBUG PARENT_SCOPE)
    unset(CMAKE_C_FLAGS PARENT_SCOPE)
    unset(CMAKE_C_FLAGS_RELEASE PARENT_SCOPE)
    unset(CMAKE_C_FLAGS_MINSIZEREL PARENT_SCOPE)
    unset(CMAKE_C_FLAGS_RELWITHDEBINFO PARENT_SCOPE)
    unset(CMAKE_C_FLAGS_DEBUG PARENT_SCOPE)
    unset(CMAKE_ASM_FLAGS PARENT_SCOPE)
    unset(CMAKE_EXE_LINKER_FLAGS PARENT_SCOPE)
    # create new definitions at parent scope
    set(CMAKE_CXX_FLAGS "-x c++ ${ARDUINO_CXX_FLAGS} -mmcu=${ARDUINO_MCU}" PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS_RELEASE "" PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS_MINSIZEREL "" PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "" PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS_DEBUG "" PARENT_SCOPE)
    set(CMAKE_C_FLAGS "-x c ${ARDUINO_C_FLAGS} -mmcu=${ARDUINO_MCU}" PARENT_SCOPE)
    set(CMAKE_C_FLAGS_RELEASE "" PARENT_SCOPE)
    set(CMAKE_C_FLAGS_MINSIZEREL "" PARENT_SCOPE)
    set(CMAKE_C_FLAGS_RELWITHDEBINFO "" PARENT_SCOPE)
    set(CMAKE_C_FLAGS_DEBUG "" PARENT_SCOPE)
    set(CMAKE_ASM_FLAGS "${ARDUINO_ASM_FLAGS} -mmcu=${ARDUINO_MCU}" PARENT_SCOPE)
    set(CMAKE_EXE_LINKER_FLAGS "${ARDUINO_EXE_LINKER_FLAGS} -mmcu=${ARDUINO_MCU}" PARENT_SCOPE)
endfunction()

#set default definitions
set_avr_compiler_flags()

add_definitions("-D__AVR__")
add_definitions("-DARDUINO_ARCH_AVR")
add_definitions("-DF_CPU=${ARDUINO_F_CPU}")

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

function(add_arduino_upload_target BASE_TARGET)
    add_custom_command(OUTPUT ${BASE_TARGET}.upload
        COMMAND ${AVRDUDE_BIN} -C\"${AVRDUDE_CFG}\" -P${ARDUINO_AVRDUDE_PORT} -b${ARDUINO_AVRDUDE_BAUD} -c${ARDUINO_AVRDUDE_PROTO} -p${ARDUINO_AVRDUDE_MCU} ${ARDUINO_AVRDUDE_EXTRACMD} -Uflash:w:\"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BASE_TARGET}\".hex:i
        DEPENDS ${BASE_TARGET}-post)
    add_custom_target(${BASE_TARGET}-upload ALL DEPENDS ${BASE_TARGET}.upload)
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
        # message(STATUS "Incorrect compiler output: ${COMPILER_OUTPUT}")
        message(FATAL_ERROR "Failed to detect default include directories!")
    endif()
endfunction()

message(STATUS "Detecting default include dirs for C language")
gcc_find_default_includes("${AVR_C}" "${CMAKE_C_FLAGS}" "AVR_C_DEFAULT_INCLUDES")

message(STATUS "Detecting default include dirs for C++ language")
gcc_find_default_includes("${AVR_CXX}" "${CMAKE_CXX_FLAGS}" "AVR_CXX_DEFAULT_INCLUDES")

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

# detect compiler's extra built-in defines that appears after adding our custom definition flags and compiler options for selected MCU and other stuff
message(STATUS "Detecting extra defines for C language")
gcc_find_extra_defines("${AVR_C}" "${CMAKE_C_FLAGS}" "AVR_C_EXTRA_DEFINES")

message(STATUS "Detecting extra defines for C++ language")
gcc_find_extra_defines("${AVR_CXX}" "${CMAKE_CXX_FLAGS}" "AVR_CXX_EXTRA_DEFINES")

# merge extra defines with current definitions
gcc_merge_defines("${AVR_C_EXTRA_DEFINES}")
gcc_merge_defines("${AVR_CXX_EXTRA_DEFINES}")

set(ARDUINO_CONFIG_INCLUDED TRUE)
