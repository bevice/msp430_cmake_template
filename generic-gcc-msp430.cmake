##########################################################################
# "THE ANY BEVERAGE-WARE LICENSE" (Revision 42 - based on beer-ware
# license):
# <dev@layer128.net> wrote this file. As long as you retain this notice
# you can do whatever you want with this stuff. If we meet some day, and
# you think this stuff is worth it, you can buy me a be(ve)er(age) in
# return. (I don't like beer much.)
#
# Matthias Kleemann
##########################################################################

##################################################
##########################################################################
# options
##########################################################################
option(WITH_MCU "Add the mCU type to the target file name." ON)
option(CXX_NO_THREAD_SAFE_STATICS "Don't use fread save statics in C++" ON)
set(CMAKE_CONFIGURATION_TYPES "Debug;Release;MinSizeRel" CACHE STRING "" FORCE)

SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_PROCESSOR msp430)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
SET(CMAKE_CROSSCOMPILING 1)
##########################################################################
# executables in use
##########################################################################
find_program(MSP430_CC msp430-elf-gcc)
find_program(MSP430_CXX msp430-elf-g++)
find_program(MSP430_OBJCOPY msp430-elf-objcopy)
find_program(MSP430_SIZE_TOOL msp430-elf-size)
find_program(MSP430_OBJDUMP msp430-elf-objdump)

##########################################################################
# toolchain starts with defining mandatory variables
##########################################################################
set(CMAKE_C_COMPILER ${MSP430_CC})
set(CMAKE_CXX_COMPILER ${MSP430_CXX})


# default programmer (hardware)
if(NOT MSP430_MSPDEBUG_DRIVER)
   set(
           MSP430_MSPDEBUG_DRIVER rf2500
      CACHE STRING "Set default mspdebug driver: rf2500"
   )
endif(NOT MSP430_MSPDEBUG_DRIVER)

# default MCU (chip)
if(NOT MSP430_MCU)
   set(
           MSP430_MCU msp430X
      CACHE STRING "Set default MCU: msp430X"
   )
endif(NOT MSP430_MCU)

if(NOT MSP430_SIZE_ARGS)
      set(MSP430_SIZE_ARGS -B)
endif(NOT MSP430_SIZE_ARGS)

##########################################################################
# check build types:
# - Debug
# - Release
# - RelWithDebInfo
#
# Release is chosen
##########################################################################
if(NOT ((CMAKE_BUILD_TYPE MATCHES Release) OR
        (CMAKE_BUILD_TYPE MATCHES RelWithDebInfo) OR
        (CMAKE_BUILD_TYPE MATCHES Debug) OR
        (CMAKE_BUILD_TYPE MATCHES MinSizeRel)))
   set(
      CMAKE_BUILD_TYPE Release
      CACHE STRING "Choose cmake build type: Debug Release RelWithDebInfo MinSizeRel"
      FORCE
   )
endif(NOT ((CMAKE_BUILD_TYPE MATCHES Release) OR
           (CMAKE_BUILD_TYPE MATCHES RelWithDebInfo) OR
           (CMAKE_BUILD_TYPE MATCHES Debug) OR
           (CMAKE_BUILD_TYPE MATCHES MinSizeRel)))

##########################################################################

##########################################################################
# target file name add-on
##########################################################################
if(WITH_MCU)
   set(MCU_TYPE_FOR_FILENAME "-${MSP430_MCU}")
else(WITH_MCU)
   set(MCU_TYPE_FOR_FILENAME "")
endif(WITH_MCU)

##########################################################################
# add_msp430_executable
# - IN_VAR: EXECUTABLE_NAME
#
# Creates targets and dependencies for MSP430 toolchain, building an
# executable. Calls add_executable with ELF file as target name, so
# any link dependencies need to be using that target, e.g. for
# target_link_libraries(<EXECUTABLE_NAME>-${MSP430_MCU}.elf ...).
##########################################################################
function(add_msp430_executable EXECUTABLE_NAME)
   if(NOT ARGN)
      message(FATAL_ERROR "No source files given for ${EXECUTABLE_NAME}.")
   endif(NOT ARGN)

   # set file names
   set(elf_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.elf)
   set(hex_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.hex)
   set(bin_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.bin)
   set(map_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.map)

   # elf file
   add_executable(${elf_file} EXCLUDE_FROM_ALL ${ARGN})

   set_target_properties(
      ${elf_file}
      PROPERTIES
         COMPILE_FLAGS "-mmcu=${MSP430_MCU}"
         LINK_FLAGS "-mmcu=${MSP430_MCU} -Wl,--gc-sections -mrelax -Wl,-Map,${map_file} ${EXTRA_FLAGS}"
   )

   add_custom_command(
      OUTPUT ${hex_file}
      COMMAND
         ${MSP430_OBJCOPY} -j .text -j .data -O ihex ${elf_file} ${hex_file}
      COMMAND
         ${MSP430_SIZE_TOOL} ${MSP430_SIZE_ARGS} ${elf_file}
      DEPENDS ${elf_file}
   )

   add_custom_command(
           OUTPUT ${bin_file}
           COMMAND
           ${MSP430_OBJCOPY} -j .text -j .data -O binary ${elf_file} ${bin_file}
           COMMAND
           ${MSP430_SIZE_TOOL} ${MSP430_SIZE_ARGS} ${elf_file}
           DEPENDS ${elf_file}
   )

   add_custom_target(
      ${EXECUTABLE_NAME}
      ALL
      DEPENDS ${hex_file} ${bin_file}
   )

   set_target_properties(
      ${EXECUTABLE_NAME}
      PROPERTIES
         OUTPUT_NAME "${elf_file}"
   )

   # clean
   get_directory_property(clean_files ADDITIONAL_MAKE_CLEAN_FILES)
   set_directory_properties(
      PROPERTIES
         ADDITIONAL_MAKE_CLEAN_FILES "${map_file}"
   )

   add_custom_target(
      upload_${EXECUTABLE_NAME}
      mspdebug  ${MSP430_MSPDEBUG_DRIVER} "prog ${elf_file}"
      DEPENDS ${elf_file}
      COMMENT "Uploading ${elf_file} to ${MSP430_MCU} using mspdebug"
   )

   # disassemble
   add_custom_target(
      disassemble_${EXECUTABLE_NAME}
      ${MSP430_OBJDUMP} -h -S ${elf_file} > ${EXECUTABLE_NAME}.lst
      DEPENDS ${elf_file}
   )

endfunction(add_msp430_executable)

##########################################################################
# add_msp430_library
# - IN_VAR: LIBRARY_NAME
#
# Calls add_library with an optionally concatenated name
# <LIBRARY_NAME>${MCU_TYPE_FOR_FILENAME}.
# This needs to be used for linking against the library, e.g. calling
# target_link_libraries(...).
##########################################################################
function(add_msp430_library LIBRARY_NAME)
   if(NOT ARGN)
      message(FATAL_ERROR "No source files given for ${LIBRARY_NAME}.")
   endif(NOT ARGN)

   set(lib_file ${LIBRARY_NAME}${MCU_TYPE_FOR_FILENAME})

   add_library(${lib_file} STATIC ${ARGN})

   set_target_properties(
      ${lib_file}
      PROPERTIES
         COMPILE_FLAGS "-mmcu=${MSP430_MCU}"
         OUTPUT_NAME "${lib_file}"
   )

   if(NOT TARGET ${LIBRARY_NAME})
      add_custom_target(
         ${LIBRARY_NAME}
         ALL
         DEPENDS ${lib_file}
      )

      set_target_properties(
         ${LIBRARY_NAME}
         PROPERTIES
            OUTPUT_NAME "${lib_file}"
      )
   endif(NOT TARGET ${LIBRARY_NAME})

endfunction(add_msp430_library)

##########################################################################
# msp430_target_link_libraries
# - IN_VAR: EXECUTABLE_TARGET
# - ARGN  : targets and files to link to
#
# Calls target_link_libraries with MSP430 target names (concatenation,
# extensions and so on.
##########################################################################
function(msp430_target_link_libraries EXECUTABLE_TARGET)
   if(NOT ARGN)
      message(FATAL_ERROR "Nothing to link to ${EXECUTABLE_TARGET}.")
   endif(NOT ARGN)

   get_target_property(TARGET_LIST ${EXECUTABLE_TARGET} OUTPUT_NAME)

   foreach(TGT ${ARGN})
      if(TARGET ${TGT})
         get_target_property(ARG_NAME ${TGT} OUTPUT_NAME)
         list(APPEND TARGET_LIST ${ARG_NAME})
      else(TARGET ${TGT})
         list(APPEND NON_TARGET_LIST ${TGT})
      endif(TARGET ${TGT})
   endforeach(TGT ${ARGN})

   target_link_libraries(${TARGET_LIST} ${NON_TARGET_LIST})
endfunction(msp430_target_link_libraries EXECUTABLE_TARGET)



##################################################################################
# status messages
##################################################################################
message(STATUS "Current mspdebug driver is: ${MSP430_MSPDEBUG_DRIVER}")
message(STATUS "Current MCU is set to: ${MSP430_MCU}")

##################################################################################
# set build type, if not already set at cmake command line
##################################################################################
if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE Release)
endif(NOT CMAKE_BUILD_TYPE)



##################################################################################
# some cmake cross-compile necessities
##################################################################################
if(DEFINED ENV{MSP430_FIND_ROOT_PATH})
   set(CMAKE_FIND_ROOT_PATH $ENV{MSP430_FIND_ROOT_PATH})
else(DEFINED ENV{MSP430_FIND_ROOT_PATH})
   message(FATAL_ERROR "Please set MSP430_FIND_ROOT_PATH in your environment.")
endif(DEFINED ENV{MSP430_FIND_ROOT_PATH})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_SYSROOT $ENV{MSP430_FIND_ROOT_PATH})
# not added automatically, since CMAKE_SYSTEM_NAME is "generic"
set(CMAKE_SYSTEM_INCLUDE_PATH "${CMAKE_FIND_ROOT_PATH}/include")
set(CMAKE_SYSTEM_LIBRARY_PATH "${CMAKE_FIND_ROOT_PATH}/lib")
include_directories("${CMAKE_FIND_ROOT_PATH}/include")
link_directories("${CMAKE_FIND_ROOT_PATH}/include")
message(STATUS "Current CMAKE_SYSTEM_INCLUDE_PATH: ${CMAKE_SYSTEM_INCLUDE_PATH}")



##################################################################################
# status messages for generating
##################################################################################
message(STATUS "Set CMAKE_FIND_ROOT_PATH to ${CMAKE_FIND_ROOT_PATH}")
message(STATUS "Set CMAKE_SYSTEM_INCLUDE_PATH to ${CMAKE_SYSTEM_INCLUDE_PATH}")
message(STATUS "Set CMAKE_SYSTEM_LIBRARY_PATH to ${CMAKE_SYSTEM_LIBRARY_PATH}")

##################################################################################
# set compiler options for build types
##################################################################################
if(CMAKE_BUILD_TYPE MATCHES Release)
   set(CMAKE_C_FLAGS_RELEASE "-Os")
   set(CMAKE_CXX_FLAGS_RELEASE "-Os")
endif(CMAKE_BUILD_TYPE MATCHES Release)

if(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)
   set(CMAKE_C_FLAGS_RELWITHDEBINFO "-Os -save-temps -g -gdwarf-3 -gstrict-dwarf")
   set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-Os -save-temps -g -gdwarf-3 -gstrict-dwarf")
endif(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)

if(CMAKE_BUILD_TYPE MATCHES Debug)
   set(CMAKE_C_FLAGS_DEBUG "-O0 -save-temps -g -gdwarf-3 -gstrict-dwarf")
   set(CMAKE_CXX_FLAGS_DEBUG "-O0 -save-temps -g -gdwarf-3 -gstrict-dwarf")
endif(CMAKE_BUILD_TYPE MATCHES Debug)

##################################################################################
# compiler options for all build types
##################################################################################
add_definitions("-fpack-struct")
add_definitions("-fshort-enums")
add_definitions("-std=c11")
add_definitions("-Wall")
#add_definitions("-Werror")
#add_definitions("-pedantic")
#add_definitions("-pedantic-errors")
#add_definitions("-funsigned-char")
add_definitions("-funsigned-bitfields")
add_definitions("-ffunction-sections")
add_definitions("-c")

set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} -std=c11)
if(CXX_NO_THREAD_SAFE_STATICS)
    set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -fno-threadsafe-statics)
endif(CXX_NO_THREAD_SAFE_STATICS)

