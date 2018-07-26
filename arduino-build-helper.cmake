set(ARDUINO_VER "10805" CACHE STRING "Arduino version define, 10805 == 1.8.5")
set(ARDUINO_MODEL "ARDUINO_AVR_PRO" CACHE STRING "Arduino board define")
set(ARDUINO_VARIANT "standard" CACHE STRING "Arduino board variant")

set(CMAKE_CXX_FLAGS "${ARDUINO_CXX_FLAGS_FULL} -DARDUINO=${ARDUINO_VER} -D${ARDUINO_MODEL}" CACHE INTERNAL "CMAKE_CXX_FLAGS")
set(CMAKE_CXX_FLAGS_RELEASE "" CACHE INTERNAL "CMAKE_CXX_FLAGS_RELEASE")
set(CMAKE_CXX_FLAGS_DEBUG "-DDEBUG" CACHE INTERNAL "CMAKE_CXX_FLAGS_DEBUG")
set(CMAKE_C_FLAGS "${ARDUINO_C_FLAGS_FULL} -DARDUINO=${ARDUINO_VER} -D${ARDUINO_MODEL}" CACHE INTERNAL "CMAKE_C_FLAGS")
set(CMAKE_C_FLAGS_RELEASE "" CACHE INTERNAL "CMAKE_C_FLAGS_RELEASE")
set(CMAKE_C_FLAGS_DEBUG "-DDEBUG" CACHE INTERNAL "CMAKE_C_FLAGS_DEBUG")
set(CMAKE_ASM_FLAGS "${ARDUINO_ASM_FLAGS_FULL} -DARDUINO=${ARDUINO_VER} -D${ARDUINO_MODEL}" CACHE INTERNAL "CMAKE_ASM_FLAGS")
set(CMAKE_EXE_LINKER_FLAGS "${EXE_LINKER_FLAGS_FULL}" CACHE INTERNAL "CMAKE_EXE_LINKER_FLAGS")

function(probe_arduino_core PROBEPATH)
    if(NOT ARDUINO_CORE_PATH)
        if(NOT EXISTS ${PROBEPATH})
           message(STATUS "Directory ${PROBEPATH} does not exist, skipping")
           return()
        endif()
        file(GLOB_RECURSE ARDUINO_CORE_SOURCES ${PROBEPATH}/*.S ${PROBEPATH}/*.c ${PROBEPATH}/*.cpp)
        if(ARDUINO_CORE_SOURCES)
            message(STATUS "Arduino-core was found at ${PROBEPATH}")
            set(ARDUINO_CORE_PATH "${PROBEPATH}" CACHE INTERNAL "arduino-core autodetected path")
            add_library(arduino-core ${ARDUINO_CORE_SOURCES})
            target_include_directories(arduino-core PUBLIC ${ARDUINO_CORE_PATH})
        else()
            message(STATUS "Directory ${PROBEPATH} does not contain source files, skipping")
        endif()
    endif()
endfunction()

function(probe_arduino_variant PROBEPATH)
    if(NOT ARDUINO_VARIANT_PATH)
        if(NOT EXISTS ${PROBEPATH})
           message(STATUS "Directory ${PROBEPATH} does not exist, skipping")
           return()
        endif()
        if(EXISTS ${PROBEPATH}/pins_arduino.h)
            message(STATUS "Arduino-variant \"${ARDUINO_VARIANT}\" was found at ${PROBEPATH}")
            set(ARDUINO_VARIANT_PATH "${PROBEPATH}" CACHE INTERNAL "arduino-variant autodetected path")
            target_include_directories(arduino-core PUBLIC ${ARDUINO_VARIANT_PATH})
        else()
            message(STATUS "Directory ${PROBEPATH} does not contain pins_arduino.h file, skipping")
        endif()
    endif()
endfunction()

function(probe_arduino_libs PROBEPATH)
    if(NOT ARDUINO_LIBS_PATH)
        if(NOT EXISTS ${PROBEPATH})
           message(STATUS "Directory ${PROBEPATH} does not exist, skipping")
           return()
        endif()
        message(STATUS "Arduino-libs directory was found at ${PROBEPATH}")
        set(ARDUINO_LIBS_PATH "${PROBEPATH}" CACHE INTERNAL "arduino-libs autodetected path")
    endif()
endfunction()

set(ARDUINO_CORE_SEARCH_PATH "" CACHE PATH "Custom arduino-core search path, will be probed first")
if(NOT ${ARDUINO_CORE_SEARCH_PATH} STREQUAL "")
    file(TO_CMAKE_PATH "${ARDUINO_CORE_SEARCH_PATH}" CM_ARDUINO_CORE_SEARCH_PATH)
    message(STATUS "Will try custom arduino-core search path at ${CM_ARDUINO_CORE_SEARCH_PATH}")
    unset(ARDUINO_CORE_PATH CACHE)
endif()

set(ARDUINO_VARIANT_SEARCH_PATH "" CACHE PATH "Custom arduino-variant search path, will be probed first")
if(NOT ${ARDUINO_VARIANT_SEARCH_PATH} STREQUAL "")
    file(TO_CMAKE_PATH "${ARDUINO_VARIANT_SEARCH_PATH}" CM_ARDUINO_VARIANT_SEARCH_PATH)
    message(STATUS "Will try custom arduino-variant search path at ${CM_ARDUINO_VARIANT_SEARCH_PATH}")
    unset(ARDUINO_VARIANT_PATH CACHE)
endif()

set(ARDUINO_LIBS_SEARCH_PATH "" CACHE PATH "Custom arduino-libs search path, will be probed first")
if(NOT ${ARDUINO_LIBS_SEARCH_PATH} STREQUAL "")
    file(TO_CMAKE_PATH "${ARDUINO_LIBS_SEARCH_PATH}" CM_ARDUINO_LIBS_SEARCH_PATH)
    message(STATUS "Will try custom arduino-variant search path at ${CM_ARDUINO_LIBS_SEARCH_PATH}")
    unset(ARDUINO_LIBS_PATH CACHE)
endif()

if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    file(TO_CMAKE_PATH "$ENV{LOCALAPPDATA}" ENV_LOCALAPPDATA)
    set(PROGRAMFILES_X86 "ProgramFiles(x86)")
    file(TO_CMAKE_PATH "$ENV{${PROGRAMFILES_X86}}" ENV_PROGRAMFILES_X86)
    file(TO_CMAKE_PATH "$ENV{ProgramFiles}" ENV_PROGRAMFILES)
    file(GLOB ARDUINO_CORE_SEARCH_DIRS
        ${CM_ARDUINO_CORE_SEARCH_PATH}
        ${ENV_LOCALAPPDATA}/Arduino*/packages/arduino/hardware/${ARDUINO_ARCH}/*/cores/arduino
        ${ENV_PROGRAMFILES}/Arduino/hardware/arduino/${ARDUINO_ARCH}/cores/arduino
        ${ENV_PROGRAMFILES_X86}/Arduino/hardware/arduino/${ARDUINO_ARCH}/cores/arduino)
    file(GLOB ARDUINO_VARIANT_SEARCH_DIRS
        ${CM_ARDUINO_VARIANT_SEARCH_PATH}
        ${ENV_LOCALAPPDATA}/Arduino*/packages/arduino/hardware/${ARDUINO_ARCH}/*/variants/${ARDUINO_VARIANT}
        ${ENV_PROGRAMFILES}/Arduino/hardware/arduino/${ARDUINO_ARCH}/variants/${ARDUINO_VARIANT}
        ${ENV_PROGRAMFILES_X86}/Arduino/hardware/arduino/${ARDUINO_ARCH}/variants/${ARDUINO_VARIANT})
    file(GLOB ARDUINO_LIBS_SEARCH_DIRS
        ${CM_ARDUINO_LIBS_SEARCH_PATH}
        ${ENV_LOCALAPPDATA}/Arduino*/packages/arduino/hardware/${ARDUINO_ARCH}/*/libraries
        ${ENV_PROGRAMFILES}/Arduino/hardware/arduino/${ARDUINO_ARCH}/libraries
        ${ENV_PROGRAMFILES_X86}/Arduino/hardware/arduino/${ARDUINO_ARCH}/libraries)
elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
  message(FATAL_ERROR "TODO")
else()
  message(FATAL_ERROR "This platform is not supported!")
endif()

foreach (ARDUINO_CORE_TEST_DIR ${ARDUINO_CORE_SEARCH_DIRS})
    probe_arduino_core ("${ARDUINO_CORE_TEST_DIR}")
endforeach ()

if(NOT ARDUINO_CORE_PATH)
    message(FATAL_ERROR "Failed to detect valid arduino-core directory")
endif()

foreach (ARDUINO_VARIANT_TEST_DIR ${ARDUINO_VARIANT_SEARCH_DIRS})
    probe_arduino_variant ("${ARDUINO_VARIANT_TEST_DIR}")
endforeach ()

if(NOT ARDUINO_VARIANT_PATH)
    message(FATAL_ERROR "Failed to detect valid arduino-variant directory")
endif()

foreach (ARDUINO_LIBS_TEST_DIR ${ARDUINO_LIBS_SEARCH_DIRS})
    probe_arduino_libs ("${ARDUINO_LIBS_TEST_DIR}")
endforeach ()

if(NOT ARDUINO_LIBS_PATH)
    message(FATAL_ERROR "Failed to detect valid arduino-libs directory")
endif()
