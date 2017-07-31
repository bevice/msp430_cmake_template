##################################################################################
# "THE ANY BEVERAGE-WARE LICENSE" (Revision 42 - based on beer-ware
# license):
# <dev@layer128.net> wrote this file. As long as you retain this notice
# you can do whatever you want with this stuff. If we meet some day, and
# you think this stuff is worth it, you can buy me a be(ve)er(age) in
# return. (I don't like beer much.)
#
# Matthias Kleemann
##################################################################################


cmake_minimum_required(VERSION 2.8)
### TOOLCHAIN SETUP AREA #################################################
# Set any variables used in the toolchain prior project() call. In that
# case they are already set and used.
##########################################################################


##################################################################################
# tools to be used for programming the MSP430
##################################################################################
set(MSP430_MCU msp430g2553)

### END TOOLCHAIN SETUP AREA #############################################
INCLUDE(generic-gcc-msp430.cmake)


##########################################################################
# name your project
##########################################################################
project(msp430_project_template)


##################################################################################
# add all sources and headers from ./src
##################################################################################
file(GLOB_RECURSE SRC_C_FILES ${PROJECT_SOURCE_DIR}/src/*.c)
file(GLOB_RECURSE SRC_CXX_FILES ${PROJECT_SOURCE_DIR}/src/*.cpp)
file(GLOB_RECURSE SRC_HEADERS ${PROJECT_SOURCE_DIR}/src/*.h)

add_msp430_executable(
        ${PROJECT_NAME}
        ${SRC_C_FILES} ${SRC_CXX_FILES} ${SRC_HEADERS}
)


