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
. "${LIBS_AUTOMATACI}/services/archive/ar.sh"




C_Build() {
        ___file_output="$1"
        ___list_sources="$2"
        ___output_type="$3"
        ___target_os="$4"
        ___target_arch="$5"
        ___directory_workspace="$6"
        ___directory_log="$7"
        ___compiler="$8"
        ___arguments="$9"


        # validate input
        if [ $(STRINGS_Is_Empty "$___file_output") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___list_sources") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___output_type") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory_workspace") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory_log") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___compiler") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arguments") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$___list_sources"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___directory_source="$(FS_Get_Directory "$___list_sources")"
        FS_Is_Directory "$___directory_source"
        if [ $? -ne 0 ]; then
                return 1
        fi

        case "$___output_type" in
        elf|exe|executable)
                # accepted - build .elf|.exe file
                ;;
        lib|dll|library)
                # accepted - build .a|.dll file
                ;;
        none)
                # accepted - build .o objects
                ;;
        *)
                return 1
        esac

        AR_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___build_list="${___directory_workspace}/build-list.txt"
        ___object_list="${___directory_workspace}/object-list.txt"
        FS_Remake_Directory "$___directory_workspace"
        FS_Remake_Directory "$___directory_log"
        FS_Remove_Silently "$___build_list"
        FS_Remove_Silently "$___object_list"

        ## (1) Scan for all files
        ___old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                __line="${__line%%#*}"
                __line="$(STRINGS_Trim_Whitespace "$__line")"
                if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                        continue
                fi

                ___platform="${__line%% *}"
                ___file="${__line##* }"
                ___file_src="${___directory_source}/${___file}"
                ___file_obj="${___directory_workspace}/$(FS_Extension_Remove "$___file" "*").o"
                ___file_log="${___directory_log}/$(FS_Extension_Remove "$___file" "*")_build.log"


                # check source file existence
                FS_Is_File "$___file_src"
                if [ $? -ne 0 ]; then
                        return 1
                fi


                # check source file compatibilities
                ___os="${___platform%%-*}"
                ___arch="${___platform##*-}"
                if [ $(STRINGS_Is_Empty "${___platform}") -ne 0 ]; then
                        # verify OS
                        if [ ! "$___os" = "any" ]; then
                                if [ ! "$___os" = "$___target_os" ]; then
                                        continue
                                fi
                        fi

                        # verify ARCH
                        if [ ! "$___arch" = "any" ]; then
                                if [ ! "$___arch" = "$___target_arch" ]; then
                                        continue
                                fi
                        fi
                fi
                ___os="$___target_os"
                ___arch="$___target_arch"


                # begin registrations
                if [ ! "$(FS_Extension_Remove "$___file_src" ".c")" = "$___file_src" ]; then
                        # it's a .c file. Register for building and linking...
                        FS_Append_File "$___build_list" "\
build|${___file_obj}|${___file_src}|${___file_log}|${___os}|${___arch}|${___compiler}|${___arguments}
"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        FS_Append_File "$___object_list" "${___file_obj}\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                elif [ ! "$(FS_Extension_Remove "$___file_src" ".o")" = "$___file_src" ]; then
                        # it's a .o file. Register only for linking...
                        FS_Make_Housing_Directory "$___file_obj"

                        FS_Copy_File "$___file_src" "$___file_obj"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        FS_Append_File "$___object_list" "${___file_obj}\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                else
                        # it's an unknown file. Bail out...
                        return 1
                fi
        done < "$___list_sources"
        IFS="$___old_IFS" && unset ___old_IFS

        ## (2) Bail early if object list is unavailable
        FS_Is_File "$___object_list"
        if [ $? -ne 0 ]; then
                return 0
        fi

        ## (3) Build all object files if found
        FS_Is_File "$___build_list"
        if [ $? -eq 0 ]; then
                SYNC_Exec_Parallel "C_Run_Parallel" "$___build_list" "$___directory_workspace"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## (4) Link all objects into the target
        FS_Remove_Silently "$___file_output"
        case "$___output_type" in
        elf|exe|executable)
                ___arguments=""
                ___old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                                continue
                        fi
                        ___arguments="${___arguments} ${__line}"
                done < "$___object_list"
                IFS="$___old_IFS" && unset ___old_IFS

                eval "${___compiler} -o ${___file_output} ${___arguments}"
                if [ $? -ne 0 ]; then
                        FS_Remove_Silently "$___file_output"
                        return 1
                fi
                ;;
        lib|dll|library)
                ___old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                                continue
                        fi

                        AR_Create "$___file_output" "$__line"
                        if [ $? -ne 0 ]; then
                                FS_Remove_Silently "$___file_output"
                                return 1
                        fi
                done < "$___object_list"
                IFS="$___old_IFS" && unset ___old_IFS
                ;;
        *)
                # assume to building only object file
                ;;
        esac


        # report status
        return 0
}




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
"


        # report status
        return 0
}




C_Is_Available() {
        # execute
        ___compiler="$(C_Get_Compiler \
                        "$PROJECT_OS" \
                        "$PROJECT_ARCH" \
                        "$PROJECT_OS" \
                        "$PROJECT_ARCH")"
        if [ $(STRINGS_Is_Empty "$___compiler") -eq 0 ]; then
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

        ___file_object="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___file_source="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___file_log="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___target_os="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___target_arch="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"

        ___compiler="${___arguments%%|*}"
        ___arguments="${___arguments#*|}"


        # validate input
        if [ $(STRINGS_Is_Empty "$___mode") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___file_object") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___file_source") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___file_log") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___target_arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___compiler") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arguments") -eq 0 ]; then
                return 1
        fi

        ___mode="$(STRINGS_To_Lowercase "$___mode")"
        case "$___mode" in
        build|build-obj|build-object)
                # accepted
                ;;
        build-exe|build-elf|build-executable)
                # accepted
                ;;
        test)
                # accepted
                ;;
        *)
                return 1
                ;;
        esac

        FS_Make_Housing_Directory "$___file_object"
        FS_Make_Housing_Directory "$___file_log"
        FS_Remove_Silently "$___file_log"

        if [ "$___mode" = "test" ]; then
                I18N_Test "$___file_object" >> "$___file_log" 2>&1
                if [ ! "$___target_os" = "$PROJECT_OS" ]; then
                        I18N_Test_Skipped >> "$___file_log" 2>&1
                        return 10 # skipped - cannot operate in host environment
                fi

                FS_Is_File "$___file_object"
                if [ $? -ne 0 ]; then
                        I18N_Test_Failed >> "$___file_log" 2>&1
                        return 1 # failed - build stage
                fi

                $___file_object >> "$___file_log" 2>&1
                if [ $? -ne 0 ]; then
                        I18N_Test_Failed >> "$___file_log" 2>&1
                        return 1 # failed - test stage
                fi


                # report status (test mode)
                return 0
        fi


        # operate in build mode
        if [ $(STRINGS_Is_Empty "$___compiler") -eq 0 ]; then
                I18N_Build_Failed >> "$___file_log" 2>&1
                return 1
        fi

        case "$___mode" in
        build-exe|build-elf|build-executable)
                ___command="\
${___compiler} ${___arguments} -o ${___file_object} ${___file_source}
"
                ;;
        *)
                # assume to building object file
                ___command="\
${___compiler} ${___arguments} -o ${___file_object} -c ${___file_source}
"
                ;;
        esac

        I18N_Run "$___command" >> "$___file_log" 2>&1
        FS_Remove_Silently "$___file_object"
        eval "$___command" >> "$___file_log" 2>&1
        if [ $? -ne 0 ]; then
                I18N_Run_Failed >> "$___file_log" 2>&1
                return 1
        fi


        # report status (build mode)
        return 0
}




C_Test() {
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

        ___compiler="$(C_Get_Compiler \
                        "$___os" \
                        "$___arch" \
                        "$PROJECT_OS" \
                        "$PROJECT_ARCH" \
        )"
        if [ $(STRINGS_Is_Empty "$___compiler") -eq 0 ]; then
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
        find "$___directory" -name '*_test.c'  -printf "%p\n" \
                | while IFS= read -r ___file_src || [ -n "$___file_src" ]; do
                if [ $(STRINGS_Is_Empty "$___file_src") -eq 0 ]; then
                        continue
                fi

                ___file_obj="$(FS_Get_Path_Relative "$___file_src" "$___directory")"
                ___file_obj="$(FS_Extension_Remove "$___file_obj" "*")"
                ___file_log="${___log}/${___file_obj}"
                case "$___os" in
                windows)
                        ___file_obj="${___workspace}/${___file_obj}.exe"
                        ;;
                *)
                        ___file_obj="${___workspace}/${___file_obj}.elf"
                        ;;
                esac

                FS_Append_File "$___build_list" "\
build-executable|${___file_obj}|${___file_src}|${___file_log}_build.log|${___os}|${___arch}|${___compiler}|${___arguments}
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                FS_Append_File "$___test_list" "\
test|${___file_obj}|${___file_src}|${___file_log}_test.log|${___os}|${___arch}|${___compiler}|${___arguments}
"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done
        IFS="$__old_IFS" && unset __old_IFS

        ## (2) Bail early if test is unavailable
        FS_Is_File "$___test_list"
        if [ $? -ne 0 ]; then
                return 0
        fi

        ## (3) Build all test artifacts
        FS_Is_File "$___build_list"
        if [ $? -eq 0 ]; then
                SYNC_Exec_Parallel "C_Run_Parallel" "$___build_list" "$___workspace"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        ## (4) Execute all test artifacts
        SYNC_Exec_Parallel "C_Run_Parallel" "$___test_list" "$___workspace"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # Report status
        return 0
}
