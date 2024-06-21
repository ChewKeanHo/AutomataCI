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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/archive/zip.sh"
. "${LIBS_AUTOMATACI}/services/compilers/c.sh"




# execute
## define workspace configurations (avoid changes unless absolute necessary)
__source_directory="${PROJECT_PATH_ROOT}/${PROJECT_C}"
__output_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
FS_Make_Directory "$__output_directory"

__log_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/build-${PROJECT_C}"
FS_Make_Directory "$__log_directory"

__tmp_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}"
FS_Make_Directory "$__tmp_directory"

__parallel_directory="${__tmp_directory}/build-parallel-C"
FS_Remake_Directory "$__parallel_directory"

__output_lib_directory="${__tmp_directory}/build-lib${PROJECT_SKU}-C"
FS_Remake_Directory "$__output_lib_directory"


## define build targets
##
## Pattern: '[OS]|[ARCH]|[COMPILER]|[TYPE]|[CONTROL_FILE]'
##         (1) '[TYPE]'         - can either be 'executable' or 'library' only.
##         (2) '[CONTROL_FILE]' - the full filepath for a AutomataCI list of
##                                targets text file.
__executable="${PROJECT_PATH_ROOT}/${PROJECT_C}/executable.txt"
__library="${PROJECT_PATH_ROOT}/${PROJECT_C}/library.txt"
__build_targets="\
darwin|amd64|clang|executable|${__executable}
darwin|amd64|clang|library|${__library}
darwin|arm64|clang|executable|${__executable}
darwin|arm64|clang|library|${__library}
js|wasm|emcc|executable|${__executable}
js|wasm|emcc|library|${__library}
linux|amd64|x86_64-linux-gnu-gcc|executable|${__executable}
linux|amd64|x86_64-linux-gnu-gcc|library|${__library}
linux|arm64|aarch64-linux-gnu-gcc|executable|${__executable}
linux|arm64|aarch64-linux-gnu-gcc|library|${__library}
linux|armle|arm-linux-gnueabi-gcc|executable|${__executable}
linux|armle|arm-linux-gnueabi-gcc|library|${__library}
linux|armhf|arm-linux-gnueabihf-gcc|executable|${__executable}
linux|armhf|arm-linux-gnueabihf-gcc|library|${__library}
linux|mips|mips-linux-gnu-gcc|executable|${__executable}
linux|mips|mips-linux-gnu-gcc|library|${__library}
linux|mipsle|mipsel-linux-gnu-gcc|executable|${__executable}
linux|mipsle|mipsel-linux-gnu-gcc|library|${__library}
linux|mips64|mips64-linux-gnuabi64-gcc|executable|${__executable}
linux|mips64|mips64-linux-gnuabi64-gcc|library|${__library}
linux|mips64le|mips64el-linux-gnuabi64-gcc|executable|${__executable}
linux|mips64le|mips64el-linux-gnuabi64-gcc|library|${__library}
linux|mips64r6|mipsisa64r6-linux-gnuabi64-gcc|executable|${__executable}
linux|mips64r6|mipsisa64r6-linux-gnuabi64-gcc|library|${__library}
linux|mips64r6le|mipsisa64r6el-linux-gnuabi64-gcc|executable|${__executable}
linux|mips64r6le|mipsisa64r6el-linux-gnuabi64-gcc|library|${__library}
linux|powerpc|powerpc-linux-gnu-gcc|executable|${__executable}
linux|powerpc|powerpc-linux-gnu-gcc|library|${__library}
linux|ppc64le|powerpc64le-linux-gnu-gcc|executable|${__executable}
linux|ppc64le|powerpc64le-linux-gnu-gcc|library|${__library}
linux|riscv64|riscv64-linux-gnu-gcc|executable|${__executable}
linux|riscv64|riscv64-linux-gnu-gcc|library|${__library}
windows|amd64|x86_64-w64-mingw32-gcc|executable|${__executable}
windows|amd64|x86_64-w64-mingw32-gcc|library|${__library}
windows|arm64|x86_64-w64-mingw32-gcc|executable|${__executable}
windows|arm64|x86_64-w64-mingw32-gcc|library|${__library}
"


## NOTE: (1) Additional files like .h files, c source code files, assets files,
##           and etc to pack into library bulk.
##
##       (2) Basic package files like README.md and LICENSE.txt are not
##           required. The Package CI job will package it automatically in later
##           CI stage. Just focus on only the end-user consumption.
##
##       (3) Pattern: '[FULL_PATH]|[NEW_FILENAME]'
__libs_files="\
${__source_directory}/libs/greeters/Vanilla.h|lib${PROJECT_SKU}.h
"


## NOTE: (1) C Compilers Optimization flags for known target OS and ARCH types.
Get_Optimization_Flags() {
        __target_os="$1"
        __target_arch="$2"


        case "$__target_os" in
        darwin)
                __arguments="$(C_Get_Strict_Settings) -fPIC"
                ;;
        windows)
                __arguments="\
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
-fno-stack-protector \
-Werror-implicit-function-declaration \
-Wno-format-security \
-Os \
-static \
"
                ;;
        *)
                __arguments="$(C_Get_Strict_Settings) -static -pie -fPIE"
                ;;
        esac

        case "$__target_arch" in
        armle|armel|armhf)
                __arguments="\
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
-fstack-protector-all \
-Werror-implicit-function-declaration \
-Wno-format-security \
-Os \
-static \
"
                ;;
        wasm)
                __arguments="\
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
-fno-stack-protector \
-Werror-implicit-function-declaration \
-Wno-format-security \
-Os \
-static \
"
                ;;
        *)
                ;;
        esac


        # report status
        printf -- "%s" "$__arguments"
        return 0
}


## NOTE: (1) perform any hard-coded overriding restrictions or gatekeeping
##           customization adjustments here (e.g. interim buggy compiler,
##           geo-politic distruption). By default, it is returning 0. Any
##           rejection shall return a non-zero value (e.g. 1).
Check_Host_Can_Build_Target() {
        case "${__target_os}-${__target_arch}" in
        *)
                # no issue by default
                return 0
                ;;
        esac
}




# build algorithms - modify only when absolute necessary
SUBROUTINE_Build() {
        __line="$1"


        # parse input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 0
        fi

        __file_output="${__line%%|*}"
        __line="${__line#*|}"

        __file_sources="${__line%%|*}"
        __line="${__line#*|}"

        __file_type="${__line%%|*}"
        __line="${__line#*|}"

        __target_os="${__line%%|*}"
        __line="${__line#*|}"

        __target_arch="${__line%%|*}"
        __line="${__line#*|}"

        __target_compiler="${__line%%|*}"
        __line="${__line#*|}"

        __arguments="${__line%%|*}"
        __line="${__line#*|}"

        __output_directory="${__line%%|*}"
        __line="${__line#*|}"

        __output_lib_directory="${__line%%|*}"
        __line="${__line#*|}"

        __tmp_directory="${__line%%|*}"
        __log_directory="${__line#*|}"


        # validate input
        if [ $(STRINGS_Is_Empty "$__file_output") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__file_sources") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__file_type") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_compiler") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__arguments") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__output_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__output_lib_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__tmp_directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__log_directory") -eq 0 ]; then
                return 1
        fi


        # prepare critical parameters
        __target="$(FS_Extension_Remove "$(FS_Get_File "$__file_output")" "*")"
        __workspace="${__tmp_directory}/build-${__target}"
        __log="${__log_directory}/${__target}"
        __file_output="${__workspace}/$(FS_Get_File "$__file_output")"

        I18N_Build_Parallel "$__file_output"
        FS_Make_Directory "$__workspace"
        FS_Make_Directory "$__log"
        C_Build "$__file_output" \
                "$__file_sources" \
                "$__file_type" \
                "$__target_os" \
                "$__target_arch" \
                "$__workspace" \
                "$__log" \
                "$__target_compiler" \
                "$__arguments"
        if [ $? -ne 0 ]; then
                I18N_Build_Failed_Parallel "$__file_output"
                return 1
        fi


        # export target
        __dest="$__output_directory"
        if [ "$__file_type" = "library" ]; then
                __dest="$__output_lib_directory"
        fi
        __dest="${__dest}/$(FS_Get_File "$__file_output")"
        FS_Remove_Silently "$__dest"
        FS_Copy_File "$__file_output" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Build_Failed_Parallel "$__file_output"
                return 1
        fi

        if [ "${__target_os}-${__target_arch}" = "js-wasm" ]; then
                __source="$(FS_Extension_Remove "$__file_output" "*").js"
                FS_Is_File "$__source"
                if [ $? -eq 0 ]; then
                        __dest="$(FS_Extension_Remove "$__dest" "*").js"
                        FS_Remove_Silently "$__dest"
                        FS_Copy_File "$__source" "$__dest"
                        if [ $? -ne 0 ]; then
                                I18N_Build_Failed_Parallel "$__file_output"
                                return 1
                        fi
                fi
        fi


        # report status
        return 0
}


## register targets and execute parallel build
__old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                continue
        fi


        # parse target data
        __source="${__line}"

        __target_os="$(STRINGS_To_Lowercase "${__source%%|*}")"
        __source="${__source#*|}"

        __target_arch="$(STRINGS_To_Lowercase ${__source%%|*})"
        __source="${__source#*|}"

        __target_compiler="${__source%%|*}"
        __source="${__source#*|}"

        __target_type="${__source%%|*}"
        __source="${__source#*|}"


        # validate input
        case "$__target_type" in
        elf|exe|executable)
                __file_output="${PROJECT_SKU}_${__target_os}-${__target_arch}"
                if [ "$__target_os" = "js" ] && [ "$__target_arch" = "wasm" ]; then
                        __file_output="${__file_output}.wasm"
                elif [ "$__target_os" = "windows" ]; then
                        __file_output="${__file_output}.exe"
                else
                        __file_output="${__file_output}.elf"
                fi
                ;;
        lib|dll|library)
                __file_output="lib${PROJECT_SKU}_${__target_os}-${__target_arch}"
                if [ "$__target_os" = "js" ] && [ "$__target_arch" = "wasm" ]; then
                        __file_output="${__file_output}.wasm"
                elif [ "$__target_os" = "windows" ]; then
                        __file_output="${__file_output}.dll"
                else
                        __file_output="${__file_output}.a"
                fi
                ;;
        *)
                return 1
                ;;
        esac
        I18N_Sync_Register "${__file_output}"

        FS_Is_File "$__source"
        if [ $? -ne 0 ]; then
                I18N_Sync_Failed
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$__target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_arch") -eq 0 ]; then
                I18N_Sync_Register_Skipped_Missing_Target
                continue
        fi

        if [ $(STRINGS_Is_Empty "$__target_compiler") -ne 0 ]; then
                OS_Is_Command_Available "$__target_compiler"
                if [ $? -ne 0 ]; then
                        I18N_Sync_Register_Skipped_Missing_Compiler
                        continue
                fi
        else
                __target_compiler="$(C_Get_Compiler \
                        "$__target_os" \
                        "$__target_arch" \
                        "$PROJECT_OS" \
                        "$PROJECT_ARCH" \
                )"
                if [ $(STRINGS_Is_Empty "$__target_compiler") -eq 0 ]; then
                        I18N_Sync_Register_Skipped_Missing_Compiler
                        continue
                fi
        fi

        Check_Host_Can_Build_Target
        if [ $? -ne 0 ]; then
                continue
        fi

        __arguments="$(Get_Optimization_Flags "$__target_os" "$__target_arch")"


        # target is healthy - register into build list
        FS_Append_File "${__parallel_directory}/parallel.txt" "\
${__file_output}|${__source}|${__target_type}|${__target_os}|${__target_arch}|${__target_compiler}|${__arguments}|${__output_directory}|${__output_lib_directory}|${__tmp_directory}|${__log_directory}
"
done <<EOF
$__build_targets
EOF
IFS="$__old_IFS" && unset __old_IFS


## Execute the build
## NOTE: For some reason, the sync flag in parallel run is not free up in this
##       layer. The underlying layer (object files building) is in parallel run
##       and shall be given that priority instead.
##
##       Hence, we can only use serial run for the time being.
SYNC_Exec_Serial \
        "SUBROUTINE_Build" \
        "${__parallel_directory}/parallel.txt" \
        "${__parallel_directory}"
if [ $? -ne 0 ]; then
        return 1
fi


## assemble additional library files
old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                continue
        fi


        # build the file
        __source="${__line%%|*}"
        __dest="${__output_lib_directory}/${__line#*|}"
        I18N_Copy "$__source" "$__dest"
        FS_Remove_Silently "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi
done <<EOF
$__libs_files
EOF


## export library package
FS_Is_Directory_Empty "$__output_lib_directory"
if [ $? -ne 0 ]; then
        __dest="${__output_directory}/lib${PROJECT_SKU}-C_any-any.tar.xz"

        I18N_Export "$__dest"
        __current_path="$PWD" && cd "$__output_lib_directory"
        TAR_Create_XZ "$__dest" "."
        ___process=$?
        cd "$__current_path" && unset __current_path
        if [ $? -ne 0 ]; then
                I18N_Export_Failed
                return 1
        fi
fi




# report status
return 0
