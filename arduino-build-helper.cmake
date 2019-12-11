set(ARDUINO_VER "10810" CACHE STRING "Arduino version define, 10810 == 1.8.10")
set(ARDUINO_MODEL "ARDUINO_AVR_PRO" CACHE STRING "Arduino board define")
set(ARDUINO_VARIANT "standard" CACHE STRING "Arduino board variant")

if(("${CMAKE_BUILD_TYPE}" STREQUAL "Debug") OR ("${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo"))
    add_definitions("-DDEBUG")
endif()

add_definitions("-DARDUINO=${ARDUINO_VER}")
add_definitions("-D${ARDUINO_MODEL}")

set(ARDUINO_EMPTY_LIBS "")
set(ARDUINO_ADDED_LIBS "")

function(fix_path_for_list PATH PATH_FIXED_VAR)
    string(REGEX REPLACE ";" "\\\\;" "${PATH_FIXED_VAR}" "${PATH}") ### fix problem with paths that contains ";" symbol, before adding it to the list
    set("${PATH_FIXED_VAR}" "${${PATH_FIXED_VAR}}" PARENT_SCOPE)
endfunction()

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
            set(ARDUINO_CORE_SOURCES ${ARDUINO_CORE_SOURCES} CACHE INTERNAL "arduino-core library sources")
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
            set(ARDUINO_VARIANT_PATH "${PROBEPATH}" PARENT_SCOPE)
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

# invocation:  add_arduino_library(<library base folder name>, <library base folder location>, [dep library1], [dep library2]>)
function(add_arduino_library LIBNAME LIBBASEDIR)
    list(FIND ARDUINO_ADDED_LIBS "${LIBNAME}" LIBNAME_TEST)
    if("${LIBNAME_TEST}" GREATER "-1")
       message(FATAL_ERROR "Arduino library \"${LIBNAME}\" was already added as build target earlier")
    endif()
    file(TO_CMAKE_PATH "${LIBBASEDIR}" LIBBASEDIR)
    if(IS_DIRECTORY "${LIBBASEDIR}/${LIBNAME}")
        set(LIBADDED FALSE)
        set(LIBDIR "${LIBBASEDIR}/${LIBNAME}")
        file(GLOB_RECURSE LIBSOURCES_RAW RELATIVE "${LIBDIR}" "${LIBDIR}/*.cpp" "${LIBDIR}/*.c" "${LIBDIR}/*.S")
        fix_path_for_list("${LIBDIR}" LIBDIR_FIX) ### fix problem with paths that contains ";" symbol, before adding it to the list
        foreach(EVAL_SOURCE IN LISTS LIBSOURCES_RAW)
            string(TOUPPER "${EVAL_SOURCE}" EVAL_SOURCE_UPPER)
            if(NOT "${EVAL_SOURCE_UPPER}" MATCHES "^EXAMPLES/.*$" )
                list(APPEND LIBSOURCES "${LIBDIR_FIX}/${EVAL_SOURCE}")
            endif()
        endforeach()
        if(LIBSOURCES)
            add_library("${LIBNAME}" "${LIBSOURCES}")
            target_link_libraries(${LIBNAME} arduino-core)
            foreach(EXTRA_DEP IN LISTS ARGN)
                list(FIND ARDUINO_EMPTY_LIBS "${EXTRA_DEP}" LIBNAME_TEST)
                if("${LIBNAME_TEST}" GREATER "-1")
                    message(STATUS "NOTE: Skipping dependency \"${EXTRA_DEP}\" library because it only contain header file(s)")
                else()
                    target_link_libraries(${LIBNAME} ${EXTRA_DEP})
                endif()
            endforeach()
            set(LIBADDED TRUE)
        endif()
        if(TARGET "${LIBNAME}")
            target_include_directories("${LIBNAME}" PUBLIC "${LIBBASEDIR}/${LIBNAME}" "${LIBBASEDIR}/${LIBNAME}/src")
            set(LIBADDED TRUE)
        else()
            include_directories("${LIBBASEDIR}/${LIBNAME}" "${LIBBASEDIR}/${LIBNAME}/src")
            set(LIBADDED TRUE)
            message(STATUS "NOTE: library \"${LIBNAME}\" contain only header file(s)")
            list(APPEND ARDUINO_EMPTY_LIBS "${LIBNAME}")
            set(ARDUINO_EMPTY_LIBS "${ARDUINO_EMPTY_LIBS}" PARENT_SCOPE)
        endif()
        if(LIBADDED)
            message(STATUS "Added library \"${LIBNAME}\" from ${LIBDIR}")
            list(APPEND ARDUINO_ADDED_LIBS "arduino-core")
            set(ARDUINO_ADDED_LIBS "${ARDUINO_ADDED_LIBS}" PARENT_SCOPE)
        else()
            message(FATAL_ERROR "Failed to detect sources for ${LIBNAME} library at ${LIBBASEDIR}")
        endif()
    else()
        message(FATAL_ERROR "Failed to detect ${LIBNAME} library at ${LIBBASEDIR}")
    endif()
endfunction()

function(add_arduino_sketch SKETCHNAME SKETCHDIR)
    file(TO_CMAKE_PATH "${SKETCHDIR}" SKETCHDIR)
    if((EXISTS ${SKETCHDIR}/${SKETCHNAME}) AND (IS_DIRECTORY ${SKETCHDIR}/${SKETCHNAME}))
        if(NOT TARGET ${SKETCHNAME})
            if(NOT EXISTS ${SKETCHDIR}/${SKETCHNAME}/${SKETCHNAME}.ino)
                message(FATAL_ERROR "Sketch directory ${SKETCHDIR}/${SKETCHNAME} does not contain ${SKETCHNAME}.ino file!")
            endif()
            file(GLOB SKETCHSOURCES ${SKETCHDIR}/${SKETCHNAME}/${SKETCHNAME}.ino ${SKETCHDIR}/${SKETCHNAME}/*.cpp ${SKETCHDIR}/${SKETCHNAME}/*.S ${SKETCHDIR}/${SKETCHNAME}/*.c)
            add_executable(${SKETCHNAME} ${SKETCHSOURCES})
            SET_SOURCE_FILES_PROPERTIES(${SKETCHDIR}/${SKETCHNAME}/${SKETCHNAME}.ino PROPERTIES LANGUAGE CXX)
            target_link_libraries(${SKETCHNAME} arduino-core)
            foreach(EXTRA_DEP IN LISTS ARGN)
                list(FIND ARDUINO_EMPTY_LIBS ${EXTRA_DEP} LIBNAME_TEST)
                if(${LIBNAME_TEST} GREATER -1)
                    message(STATUS "NOTE: Skipping dependency \"${EXTRA_DEP}\" library because it only contain header file(s)")
                else()
                    target_link_libraries(${SKETCHNAME} ${EXTRA_DEP})
                endif()
            endforeach()
            message(STATUS "Added \"${SKETCHNAME}\" sketch-target from ${SKETCHDIR}/${SKETCHNAME} directory")
        endif()
    else()
        message(FATAL_ERROR "Sketch directory is missing ${SKETCHDIR}/${SKETCHNAME}")
    endif()
endfunction()

set(ARDUINO_CORE_SEARCH_PATH "" CACHE PATH "Custom arduino-core search path, will be probed first")
if(NOT ${ARDUINO_CORE_SEARCH_PATH} STREQUAL "")
    file(TO_CMAKE_PATH "${ARDUINO_CORE_SEARCH_PATH}" CM_ARDUINO_CORE_SEARCH_PATH)
    if(NOT "${ARDUINO_CORE_SEARCH_PATH}" STREQUAL "${ARDUINO_CORE_SEARCH_PATH_PREV}") #if ARDUINO_CORE_SEARCH_PATH was changed
      message(STATUS "Will try custom arduino-core search path at ${CM_ARDUINO_CORE_SEARCH_PATH}")
      unset(ARDUINO_CORE_PATH CACHE)
      set(ARDUINO_CORE_SEARCH_PATH_PREV "${ARDUINO_CORE_SEARCH_PATH}" CACHE INTERNAL "ARDUINO_CORE_SEARCH_PATH_PREV")
    endif()
elseif(NOT "${ARDUINO_CORE_SEARCH_PATH_PREV}" STREQUAL "") #if ARDUINO_CORE_SEARCH_PATH was unset after being used in previous run
    message(STATUS "Removing custom arduino-core search path from evaluation")
    unset(ARDUINO_CORE_SEARCH_PATH_PREV CACHE)
    unset(ARDUINO_CORE_PATH CACHE)
endif()

set(ARDUINO_VARIANTS_SEARCH_PATH "" CACHE PATH "Custom arduino-variant search path, will be probed first")
if(NOT ${ARDUINO_VARIANTS_SEARCH_PATH} STREQUAL "")
    file(TO_CMAKE_PATH "${ARDUINO_VARIANTS_SEARCH_PATH}" CM_ARDUINO_VARIANTS_SEARCH_PATH)
    if(NOT "${ARDUINO_VARIANTS_SEARCH_PATH}" STREQUAL "${ARDUINO_VARIANTS_SEARCH_PATH_PREV}") #if ARDUINO_VARIANTS_SEARCH_PATH was changed
      message(STATUS "Will try custom arduino-variants search path at ${CM_ARDUINO_VARIANTS_SEARCH_PATH}")
      unset(ARDUINO_VARIANT_PATH)
      set(ARDUINO_VARIANTS_SEARCH_PATH_PREV "${ARDUINO_VARIANTS_SEARCH_PATH}" CACHE INTERNAL "ARDUINO_VARIANTS_SEARCH_PATH_PREV")
    endif()
elseif(NOT "${ARDUINO_VARIANTS_SEARCH_PATH_PREV}" STREQUAL "") #if ARDUINO_VARIANTS_SEARCH_PATH was unset after being used in previous run
    message(STATUS "Removing custom arduino-variants search path from evaluation")
    unset(ARDUINO_VARIANTS_SEARCH_PATH_PREV CACHE)
    unset(ARDUINO_VARIANT_PATH)
endif()

set(ARDUINO_LIBS_SEARCH_PATH "" CACHE PATH "Custom arduino-libs search path, will be probed first")
if(NOT ${ARDUINO_LIBS_SEARCH_PATH} STREQUAL "")
    file(TO_CMAKE_PATH "${ARDUINO_LIBS_SEARCH_PATH}" CM_ARDUINO_LIBS_SEARCH_PATH)
    if(NOT "${ARDUINO_LIBS_SEARCH_PATH}" STREQUAL "${ARDUINO_LIBS_SEARCH_PATH_PREV}") #if ARDUINO_LIBS_SEARCH_PATH was changed
      message(STATUS "Will try custom arduino-libs search path at ${CM_ARDUINO_LIBS_SEARCH_PATH}")
      unset(ARDUINO_LIBS_PATH CACHE)
      set(ARDUINO_LIBS_SEARCH_PATH_PREV "${ARDUINO_LIBS_SEARCH_PATH}" CACHE INTERNAL "ARDUINO_LIBS_SEARCH_PATH_PREV")
    endif()
elseif(NOT "${ARDUINO_LIBS_SEARCH_PATH_PREV}" STREQUAL "") #if ARDUINO_LIBS_SEARCH_PATH was unset after being used in previous run
    message(STATUS "Removing custom arduino-libs search path from evaluation")
    unset(ARDUINO_LIBS_SEARCH_PATH_PREV CACHE)
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
        ${CM_ARDUINO_VARIANTS_SEARCH_PATH}/${ARDUINO_VARIANT}
        ${ENV_LOCALAPPDATA}/Arduino*/packages/arduino/hardware/${ARDUINO_ARCH}/*/variants/${ARDUINO_VARIANT}
        ${ENV_PROGRAMFILES}/Arduino/hardware/arduino/${ARDUINO_ARCH}/variants/${ARDUINO_VARIANT}
        ${ENV_PROGRAMFILES_X86}/Arduino/hardware/arduino/${ARDUINO_ARCH}/variants/${ARDUINO_VARIANT})
    file(GLOB ARDUINO_LIBS_SEARCH_DIRS
        ${CM_ARDUINO_LIBS_SEARCH_PATH}
        ${ENV_LOCALAPPDATA}/Arduino*/packages/arduino/hardware/${ARDUINO_ARCH}/*/libraries
        ${ENV_PROGRAMFILES}/Arduino/hardware/arduino/${ARDUINO_ARCH}/libraries
        ${ENV_PROGRAMFILES_X86}/Arduino/hardware/arduino/${ARDUINO_ARCH}/libraries)
elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
    file(TO_CMAKE_PATH "$ENV{HOME}" ENV_HOME)
    file(GLOB ARDUINO_CORE_SEARCH_DIRS
        ${CM_ARDUINO_CORE_SEARCH_PATH}
        ${ENV_HOME}/.arduino*/packages/arduino/hardware/${ARDUINO_ARCH}/*/cores/arduino
        ${ENV_HOME}/arduino-*/hardware/arduino/${ARDUINO_ARCH}/cores/arduino)
    file(GLOB ARDUINO_VARIANT_SEARCH_DIRS
        ${CM_ARDUINO_VARIANTS_SEARCH_PATH}/${ARDUINO_VARIANT}
        ${ENV_HOME}/.arduino*/packages/arduino/hardware/${ARDUINO_ARCH}/*/variants/${ARDUINO_VARIANT}
        ${ENV_HOME}/arduino-*/hardware/arduino/${ARDUINO_ARCH}/variants/${ARDUINO_VARIANT})
    file(GLOB ARDUINO_LIBS_SEARCH_DIRS
        ${CM_ARDUINO_LIBS_SEARCH_PATH}
        ${ENV_HOME}/.arduino*/packages/arduino/hardware/${ARDUINO_ARCH}/*/libraries
        ${ENV_HOME}/arduino-*/hardware/arduino/${ARDUINO_ARCH}/libraries)
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

#add arduino-core library
add_library(arduino-core ${ARDUINO_CORE_SOURCES})
target_include_directories(arduino-core PUBLIC ${ARDUINO_CORE_PATH})
target_include_directories(arduino-core PUBLIC ${ARDUINO_VARIANT_PATH})
list(APPEND ARDUINO_ADDED_LIBS arduino-core)
message(STATUS "Added arduino-core library from ${ARDUINO_CORE_PATH}")
