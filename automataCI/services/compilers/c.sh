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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"




C::get_compiler() {
        #__os="$1"
        #__arch="$2"
        #__base_os="$3"
        #__base_arch="$4"
        #__compiler="$5"


        # execute
        if [ ! -z "$5" ]; then
                OS_Is_Command_Available "$5"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$5"
                        return 0
                else
                        printf -- ""
                        return 1
                fi
        fi

        __compiler="$(C::get_compiler_by_arch "$1" "$2")"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi

        __compiler="$(C::get_compiler_common "$1" "$2" "$3" "$4")"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi


        # report status
        printf -- ""
        return 1
}




C::get_compiler_by_arch() {
        #__os="$1"
        #__arch="$2"


        # execute
        case "$2" in
        amd64)
                case "$1" in
                windows)
                        __compiler="x86_64-w64-mingw32-gcc"
                        ;;
                darwin)
                        __compiler="clang-17"
                        OS_Is_Command_Available "$__compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$__compiler"
                                return 0
                        fi

                        __compiler="clang-15"
                        OS_Is_Command_Available "$__compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$__compiler"
                                return 0
                        fi

                        __compiler="clang-14"
                        ;;
                *)
                        __compiler="x86_64-linux-gnu-gcc"
                        OS_Is_Command_Available "$__compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$__compiler"
                                return 0
                        fi

                        __compiler="x86_64-elf-gcc"
                        ;;
                esac
                ;;
        arm|armel)
                __compiler="arm-linux-gnueabi-gcc"
                OS_Is_Command_Available "$__compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$__compiler"
                        return 0
                fi

                __compiler="arm-none-gnueabi-gcc"
                ;;
        armhf)
                __compiler="arm-linux-gnueabihf-gcc"
                ;;
        arm64)
                case "$1" in
                windows)
                        __compiler="x86_64-w64-mingw32-gcc"
                        ;;
                darwin)
                        __compiler="clang-17"
                        OS_Is_Command_Available "$__compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$__compiler"
                                return 0
                        fi

                        __compiler="clang-15"
                        OS_Is_Command_Available "$__compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$__compiler"
                                return 0
                        fi

                        __compiler="clang-14"
                        ;;
                *)
                        __compiler="aarch64-linux-gnu-gcc"
                        ;;
                esac
                ;;
        avr)
                __compiler="avr-gcc"
                OS_Is_Command_Available "$__compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$__compiler"
                        return 0
                fi

                __compiler="clang-17"
                OS_Is_Command_Available "$__compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$__compiler"
                        return 0
                fi

                __compiler="clang-15"
                OS_Is_Command_Available "$__compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$__compiler"
                        return 0
                fi

                __compiler="clang-14"
                ;;
        i386)
                case "$1" in
                windows)
                        __compiler="x86_64-w64-mingw32-gcc"
                        ;;
                darwin)
                        __compiler="clang-17"
                        OS_Is_Command_Available "$__compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$__compiler"
                                return 0
                        fi

                        __compiler="clang-15"
                        OS_Is_Command_Available "$__compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$__compiler"
                                return 0
                        fi

                        __compiler="clang-14"
                        ;;
                *)
                        __compiler="i686-linux-gnu-gcc"
                        OS_Is_Command_Available "$__compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$__compiler"
                                return 0
                        fi

                        __compiler="i686-elf-gcc"
                        ;;
                esac
                ;;
        mips)
                __compiler="mips-linux-gnu-gcc"
                ;;
        mipsle)
                __compiler="mipsel-linux-gnu-gcc"
                ;;
        mips64)
                __compiler="mips64-linux-gnuabi64-gcc"
                ;;
        mips64le|mips64el)
                __compiler="mips64el-linux-gnuabi64-gcc"
                ;;
        mips32r6|mipsisa32r6)
                __compiler="mipsisa32r6-linux-gnu-gcc"
                ;;
        mips64r6|mipsisa64r6)
                __compiler="mipsisa64r6-linux-gnuabi64-gcc"
                ;;
        mips32r6le|mipsisa32r6le|mipsisa32r6el)
                __compiler="mipsisa32r6el-linux-gnu-gcc"
                ;;
        mips64r6le|mipsisa64r6le|mipsisa64r6el)
                __compiler="mipsisa64r6el-linux-gnuabi64-gcc"
                ;;
        powerpc)
                __compiler="powerpc-linux-gnu-gcc"
                ;;
        ppc64le|ppc64el)
                __compiler="powerpc64le-linux-gnu-gcc"
                ;;
        riscv64)
                __compiler="riscv64-elf-gcc"
                ;;
        s390x)
                __compiler="s390x-linux-gnu-gcc"
                ;;
        wasm)
                __compiler="emcc"
                ;;
        *)
                ;;
        esac

        OS_Is_Command_Available "$__compiler"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi


        # report status
        printf -- ""
        return 1
}




C::get_compiler_common() {
        __os="$1"
        __arch="$2"
        __base_os="$3"
        __base_arch="$4"


        # execute
        if [ "$__arch" != "$__base_arch" ] || [ "$__os" != "$__base_os" ]; then
                __compiler=""
                printf -- ""
                return 1
        fi

        __compiler="gcc"
        OS_Is_Command_Available "$__compiler"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi

        __compiler="cc"
        OS_Is_Command_Available "$__compiler"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi

        __compiler="clang17"
        OS_Is_Command_Available "$__compiler"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi

        __compiler="clang15"
        OS_Is_Command_Available "$__compiler"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi

        __compiler="clang14"
        OS_Is_Command_Available "$__compiler"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi

        __compiler="clang"
        OS_Is_Command_Available "$__compiler"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$__compiler"
                return 0
        fi


        # report status
        printf -- ""
        return 1
}




C::get_strict_settings() {
        # execute
        printf -- "%b" "\
-Wall \
-Wextra \
-std=gnu89 \
-pedantic \
-Wstrict-prototypes \
-Wold-style-definition \
-Wundef \
-Wno-trigraphs \
-fno-strict-aliasing \
-fno-common \
-fshort-wchar \
-fstack-protector-all \
-Werror-implicit-function-declaration \
-Wno-format-security \
-pie -fPIE \
"


        # report status
        return 0
}




C::is_available() {
        # execute
        if [ ! -z "$(C::get_compiler_by_arch "windows" "amd64")" -a \
                ! -z "$(C::get_compiler_by_arch "darwin" "amd64")" -a \
                ! -z "$(C::get_compiler_by_arch "" "amd64")" -a \
                ! -z "$(C::get_compiler_by_arch "" "arm")" -a \
                ! -z "$(C::get_compiler_by_arch "windows" "arm64")" -a \
                ! -z "$(C::get_compiler_by_arch "darwin" "arm64")" -a \
                ! -z "$(C::get_compiler_by_arch "" "arm64")" -a \
                ! -z "$(C::get_compiler_by_arch "" "i386")" -a \
                ! -z "$(C::get_compiler_by_arch "" "wasm")" -a \
                ! -z "$(C::get_compiler_by_arch "" "riscv64")" ]; then
                return 0
        fi


        # report status
        return 1
}
