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
. "${LIBS_AUTOMATACI}/services/compilers/c.sh"




# execute
__output_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
FS_Remake_Directory "$__output_directory"

__log_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}"
FS_Make_Directory "$__log_directory"

__tmp_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}"
FS_Make_Directory "$__tmp_directory"

__parallel_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/c-parallel"
FS_Remake_Directory "$__parallel_directory"

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

__placeholders="\
${PROJECT_SKU}-src_any-any
${PROJECT_SKU}-homebrew_any-any
${PROJECT_SKU}-chocolatey_any-any
${PROJECT_SKU}-msi_any-any
"


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
        __arguments="${__line#*|}"


        # validate input
        if [ $(STRINGS_Is_Empty "$__file_output") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__file_sources") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__file_type") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_compiler") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__arguments") -eq 0 ]; then
                return 1
        fi


        # prepare critical parameters
        __target="$(FS_Extension_Remove "$(FS_Get_File "$__file_output")" "*")"
        __workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/build-${__target}"
        __log="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/build-${__target}"
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
        __dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/$(FS_Get_File "$__file_output")"
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




# register targets and execute parallel build
old_IFS="$IFS"
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
                if [ "$__target_os" = "windows" ]; then
                        __file_output="${__file_output}.exe"
                else
                        __file_output="${__file_output}.elf"
                fi
                ;;
        lib|dll|library)
                __file_output="lib${PROJECT_SKU}_${__target_os}-${__target_arch}"
                if [ "$__target_os" = "windows" ]; then
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
                __target_compiler="$(C_Get_Compiler "$__target_os" "$__target_arch")"
                if [ $(STRINGS_Is_Empty "$__target_compiler") -eq 0 ]; then
                        I18N_Sync_Register_Skipped_Missing_Compiler
                        continue
                fi
        fi


        ## NOTE: perform any hard-coded host system restrictions or gatekeeping
        ##       customization adjustments here.
        case "${__target_os}-${__target_arch}" in
        *)
                # accepted
                ;;
        esac


        # formulate compiler optimization flags
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
                __arguments="$(C_Get_Strict_Settings) -pie -fPIE"
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


        # target is healthy - register into build list
        FS_Append_File "${__parallel_directory}/parallel.txt" "\
${__file_output}|${__source}|${__target_type}|${__target_os}|${__target_arch}|${__target_compiler}|${__arguments}
"
done <<EOF
$__build_targets
EOF
IFS="$__old_IFS" && unset __old_IFS


# NOTE: For some reason, the sync flag in parallel run is not free up at this
#       layer. The underlying layer (object files building) is in parallel run
#       and shall be given that priority.
#
#       Hence, we can only use serial run for the time being.
SYNC_Exec_Serial \
        "SUBROUTINE_Build" \
        "${__parallel_directory}/parallel.txt" \
        "${__parallel_directory}"
if [ $? -ne 0 ]; then
        return 1
fi




# placeholding flag files
old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        if [ $(STRINGS_Is_Empty "$__line") -eq 0 ]; then
                continue
        fi


        # build the file
        __file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__line}"
        I18N_Build "$__line"
        FS_Remove_Silently "$__file"
        FS_Touch_File "$__file"
        if [ $? -ne 0 ]; then
                I18N_Build_Failed
                return 1
        fi
done <<EOF
$__placeholders
EOF




# compose documentations




# report status
return 0
