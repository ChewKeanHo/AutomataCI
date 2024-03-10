#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/c.sh"




INSTALLER::setup_angular() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "ng"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        INSTALLER::setup_node
        if [ $? -ne 0 ]; then
                return 1
        fi

        npm install -g @angular/cli
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




INSTALLER::setup_c() {
        #__os="$1"
        #__arch="$2"


        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        C::is_available
        if [ $? -eq 0 ]; then
                return 0
        fi

        if [ "$1" = "darwin" ]; then
                brew install \
                        aarch64-elf-gcc \
                        arm-none-eabi-gcc \
                        riscv64-elf-gcc \
                        x86_64-elf-gcc \
                        i686-elf-gcc \
                        mingw-w64 \
                        emscripten \
                        gcc
        else
                brew install \
                        aarch64-elf-gcc \
                        arm-none-eabi-gcc \
                        riscv64-elf-gcc \
                        x86_64-elf-gcc \
                        i686-elf-gcc \
                        mingw-w64 \
                        emscripten \
                        llvm
        fi
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




INSTALLER::setup_nim() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "nim"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        brew install nim


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




INSTALLER::setup_node() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "npm"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        brew install node
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
