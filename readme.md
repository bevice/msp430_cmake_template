# MSP430 Cmake Template Project #

## Requirements ##

* MSP430-GCC opensource toolchain (http://www.ti.com/tool/msp430-gcc-opensource)
* mspdebug (for uploading firmware)

## Settings ##

Set environment variable *MSP430_FIND_ROOT_PATH* to the installed msp430-gcc-opensource toolchain, eg: 

    export MSP430_FIND_ROOT_PATH=~/toolchains/msp430_gcc

in ```~/.profile``` file


## Extras ##

Simple bash script for easy create new project:

    #!/bin/bash
    git clone git@github.com:bevice/msp430_cmake_template.git $1
    cd $1
    git remote remove origin
    sed -i '' -e   "s/msp430_project_template/$1/g" CMakeLists.txt
    echo "# $1 #" > readme.md

Command: ```~/bin/create_msp430_project test``` will clone the template into test directory, 
remove origin repository, rename project to "test" and clean this file
