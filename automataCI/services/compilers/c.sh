#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/sync.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




C_Get_Compiler() {
        #___os="$1"
        #___arch="$2"
        #___base_os="$3"
        #___base_arch="$4"
        #___compiler="$5"


        # execute
        if [ $(STRINGS_Is_Empty "$5") -ne 0 ]; then
                OS_Is_Command_Available "$5"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$5"
                        return 0
                else
                        printf -- ""
                        return 1
                fi
        fi

        case "${1}-${2}" in
        darwin-amd64|darwin-arm64)
                ___compiler="clang-17"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                ___compiler="clang-15"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                ___compiler="clang-14"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="clang"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        js-wasm)
                ___compiler="emcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi
                ;;
        linux-amd64)
                ___compiler="x86_64-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                ___compiler="x86_64-elf-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-arm64)
                ___compiler="aarch64-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                ___compiler="aarch64-elf-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-arm|linux-armel|linux-armle)
                ___compiler="arm-linux-gnueabi-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                ___compiler="arm-linux-eabi-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                ___compiler="arm-none-eabi-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-armhf)
                ___compiler="arm-linux-gnueabihf-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-i386)
                ___compiler="i686-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                ___compiler="i686-elf-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-mips)
                ___compiler="mips-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-mipsle|linux-mipsel)
                ___compiler="mipsel-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-mips64)
                ___compiler="mips64-linux-gnuabi64-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-mips64le|linux-mips64el)
                ___compiler="mips64el-linux-gnuabi64-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-mips32r6|linux-mipsisa32r6)
                ___compiler="mipsisa32r6-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-mips64r6|linux-mipsisa64r6)
                ___compiler="mipsisa64r6-linux-gnuabi64-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-mips32r6le|linux-mipsisa32r6le|linux-mipsisa32r6el)
                ___compiler="mipsisa32r6el-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-mips64r6le|linux-mipsisa64r6le|linux-mipsisa64r6el)
                ___compiler="mipsisa64r6el-linux-gnuabi64-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-powerpc)
                ___compiler="powerpc-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-ppc64le|linux-ppc64el)
                ___compiler="powerpc64le-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-riscv64)
                ___compiler="riscv64-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                ___compiler="riscv64-elf-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        linux-s390x)
                __compiler="s390x-linux-gnu-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi

                if [ "$1" = "$3" ] || [ "$2" = "$4" ]; then
                        ___compiler="gcc"
                        OS_Is_Command_Available "$___compiler"
                        if [ $? -eq 0 ]; then
                                printf -- "%b" "$___compiler"
                                return 0
                        fi
                fi
                ;;
        none-avr)
                ___compiler="avr-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi
                ;;
        windows-amd64)
                ___compiler="x86_64-w64-mingw32-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi
                ;;
        windows-i386)
                ___compiler="i686-w64-mingw32-gcc"
                OS_Is_Command_Available "$___compiler"
                if [ $? -eq 0 ]; then
                        printf -- "%b" "$___compiler"
                        return 0
                fi
                ;;
        wasip1-wasm)
                ;;
        *)
                ;;
        esac


        # report status
        printf -- ""
        return 1
}




C_Get_Strict_Settings() {
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
-Os \
-static \
"


        # report status
        return 0
}




C_Is_Available() {
        # execute
        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "$PROJECT_OS" "$PROJECT_ARCH")") -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}




C_Setup() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "linux" "arm64")") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -ne 0 ]; then
                brew install aarch64-elf-gcc
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "linux" "riscv64")") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -ne 0 ]; then
                brew install riscv64-elf-gcc
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "linux" "arm")") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -ne 0 ]; then
                brew install arm-none-eabi-gcc
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "linux" "amd64")") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -ne 0 ]; then
                brew install x86_64-elf-gcc
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "linux" "i386")") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -ne 0 ]; then
                brew install i686-elf-gcc
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "windows" "amd64")") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -ne 0 ]; then
                brew install mingw-w64
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "js" "wasm")") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -ne 0 ]; then
                brew install emscripten
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$(C_Get_Compiler "$PROJECT_OS" "$PROJECT_ARCH")") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -ne 0 ]; then
                case "$PROJECT_OS" in
                darwin)
                        brew install gcc
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                *)
                        brew install llvm
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                        ;;
                esac
        fi


        # report status
        return 0
}




C_Run_Parallel() {
        #___line="$1"


        # parse input
        ___mode="${1%%|*}"
        ___arguments="${1#*|}"

        ___directory_source="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___directory_workspace="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___directory_log="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___target="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___target_os="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___target_arch="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"


        # validate input
        if [ $(STRINGS_Is_Empty "$___mode") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory_source") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory_workspace") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory_log") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arguments") -eq 0 ]; then
                return 1
        fi

        ___mode="$(STRINGS_To_Lowercase "$___mode")"
        case "$___mode" in
        build|test)
                # accepted
                ;;
        *)
                return 1
                ;;
        esac

        ___target="$(FS_Get_Path_Relative "$___target" "$___directory_source")"
        ___directory_target="$(FS_Get_Directory "$___target")"
        ___file_target="$(FS_Get_File "$___target")"

        ___file_log="$___directory_log"
        ___file_output="$___directory_workspace"
        if [ ! "$___directory_target" = "$___file_target" ]; then
                # there are sub-directories
                ___file_log="${___file_log}/${___directory_target}"
                ___file_output="${___file_output}/${___directory_target}"
        fi

        ___file_target="$(FS_Extension_Remove "$___file_target" "*")"
        if [ "$___mode" = "test" ]; then
                ___file_log="${___file_log}/${___file_target}_test.log"
        else
                ___file_log="${___file_log}/${___file_target}_build.log"
        fi
        FS_Make_Housing_Directory "$___file_log"

        ___file_output="${___file_output}/${___file_target}"
        case "$___target_os" in
        windows)
                ___file_output="${___file_output}.exe"
                ;;
        *)
                ___file_output="${___file_output}.elf"
                ;;
        esac
        FS_Make_Housing_Directory "$___file_output"

        if [ "$___mode" = "test" ]; then
                I18N_Test "$___file_output" >> "$___file_log" 2>&1
                if [ ! "$___target_os" = "$PROJECT_OS" ]; then
                        I18N_Test_Skipped >> "$___file_log" 2>&1
                        return 10 # skipped - cannot operate in host environment
                fi

                FS_Is_File "$___file_output"
                if [ $? -ne 0 ]; then
                        I18N_Test_Failed >> "$___file_log" 2>&1
                        return 1 # failed - build stage
                fi

                $___file_output >> "$___file_log" 2>&1
                if [ $? -ne 0 ]; then
                        I18N_Test_Failed >> "$___file_log" 2>&1
                        return 1 # failed - test stage
                fi


                # report status (test mode)
                return 0
        fi


        # operate in build mode
        ___compiler="$(C_Get_Compiler "$___target_os" "$___target_arch")"
        if [ $(STRINGS_Is_Empty "$___compiler") -eq 0 ]; then
                I18N_Build_Failed >> "$___file_log" 2>&1
                return 1
        fi

        ___command="\
${___compiler} ${___arguments} -o ${___file_output} ${___directory_source}/${___target}
"


        # execute
        I18N_Build "$___command" >> "$___file_log" 2>&1
        $___command >> "$___file_log" 2>&1
        if [ $? -ne 0 ]; then
                I18N_Build_Failed >> "$___file_log" 2>&1
                return 1
        fi


        # report status (build mode)
        return 0
}




C_Run_Test() {
        ___directory="$1"
        ___os="$2"
        ___arch="$3"
        ___arguments="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arguments") -eq 0 ]; then
                return 1
        fi

        C_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/test-${PROJECT_C}"
        ___log="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/test-${PROJECT_C}"
        ___build_list="${___workspace}/build-list.txt"
        ___test_list="${___workspace}/test-list.txt"
        FS_Remake_Directory "$___workspace"
        FS_Remake_Directory "$___log"

        ## (1) Scan for all test files
        __old_IFS="$IFS"
        find "$___directory" -name '*_test.c' -print0 \
                | while IFS="" read -r __line || [ -n "$__line" ]; do
                FS_Append_File "$___build_list" "\
build|${___directory}|${___workspace}|${___log}|${__line}|${___os}|${___arch}|${___arguments}
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                FS_Append_File "$___test_list" "\
test|${___directory}|${___workspace}|${___log}|${__line}|${___os}|${___arch}|${___arguments}
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done
        IFS="$__old_IFS" && unset __old_IFS

        ## (2) Bail early if test is unavailable
        FS_Is_File "$___build_list"
        if [ $? -ne 0 ]; then
                return 0
        fi

        FS_Is_File "$___test_list"
        if [ $? -ne 0 ]; then
                return 0
        fi

        ## (3) Build all test artifacts
        SYNC_Exec_Parallel "C_Run_Parallel" "$___build_list" "$___workspace"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ## (4) Execute all test artifacts
        SYNC_Exec_Parallel "C_Run_Parallel" "$___test_list" "$___workspace"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # Report status
        return 0
}
