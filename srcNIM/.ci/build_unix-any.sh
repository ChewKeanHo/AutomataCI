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
. "${LIBS_AUTOMATACI}/services/compilers/nim.sh"
. "${LIBS_AUTOMATACI}/services/compilers/c.sh"




# execute
I18N_Activate_Environment
NIM_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


__output_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
FS_Remake_Directory "$__output_directory"

__log_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}"
FS_Make_Directory "$__log_directory"

__tmp_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}"
FS_Make_Directory "$__tmp_directory"

__parallel_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/nim-parallel"
FS_Remake_Directory "$__parallel_directory"


__main="${PROJECT_PATH_ROOT}/${PROJECT_NIM}/${PROJECT_SKU}.nim"

__build_targets="\
darwin|amd64|clang|${__main}
darwin|arm64|clang|${__main}
js|wasm||${__main}
js|js|emcc|${__main}
linux|amd64|x86_64-linux-gnu-gcc|${__main}
linux|arm64|aarch64-linux-gnu-gcc|${__main}
linux|armle|arm-linux-gnueabi-gcc|${__main}
linux|armhf|arm-linux-gnueabihf-gcc|${__main}
linux|mips|mips-linux-gnu-gcc|${__main}
linux|mipsle|mipsel-linux-gnu-gcc|${__main}
linux|mips64|mips64-linux-gnuabi64-gcc|${__main}
linux|mips64le|mips64el-linux-gnuabi64-gcc|${__main}
linux|mips64r6|mipsisa64r6-linux-gnuabi64-gcc|${__main}
linux|mips64r6le|mipsisa64r6el-linux-gnuabi64-gcc|${__main}
linux|powerpc|powerpc-linux-gnu-gcc|${__main}
linux|ppc64le|powerpc64le-linux-gnu-gcc|${__main}
linux|riscv64|riscv64-linux-gnu-gcc|${__main}
windows|amd64|x86_64-w64-mingw32-gcc|${__main}
windows|arm64|x86_64-w64-mingw32-gcc|${__main}
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

        __target_name="${__line%%|*}"
        __line="${__line#*|}"

        __target_os="${__line%%|*}"
        __line="${__line#*|}"

        __target_arch="${__line%%|*}"
        __line="${__line#*|}"

        __target_compiler="${__line%%|*}"
        __line="${__line#*|}"

        __dir_output="${__line%%|*}"
        __line="${__line#*|}"

        __dir_workspace="${__line%%|*}"
        __line="${__line#*|}"

        __dir_log="${__line%%|*}"
        __source="${__line#*|}"


        # validate input
        if [ $(STRINGS_Is_Empty "$__target_name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_compiler") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__dir_output") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__dir_workspace") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__dir_log") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__source") -eq 0 ]; then
                return 1
        fi

        if [ "$__target_compiler" = "native" ]; then
                __target_compiler=""
        fi


        # prepare critical parameters
        __target="${__target_name}_${__target_os}-${__target_arch}"
        ___arguments_c="\
compileToC \
--passC:-Wall --passL:-Wall \
--passC:-Wextra --passL:-Wextra \
--passC:-std=gnu89 --passL:-std=gnu89 \
--passC:-pedantic --passL:-pedantic \
--passC:-Wstrict-prototypes --passL:-Wstrict-prototypes \
--passC:-Wold-style-definition --passL:-Wold-style-definition \
--passC:-Wundef --passL:-Wundef \
--passC:-Wno-trigraphs --passL:-Wno-trigraphs \
--passC:-fno-strict-aliasing --passL:-fno-strict-aliasing \
--passC:-fno-common --passL:-fno-common \
--passC:-fshort-wchar --passL:-fshort-wchar \
--passC:-fstack-protector-all --passL:-fstack-protector-all \
--passC:-Werror-implicit-function-declaration --passL:-Werror-implicit-function-declaration \
--passC:-Wno-format-security --passL:-Wno-format-security \
--passC:-Os --passL:-Os \
--passC:-g0 --passL:-g0 \
--passC:-flto --passL:-flto \
"
        ___arguments_nim="\
--mm:orc \
--define:release \
--opt:size \
--colors:on \
--styleCheck:off \
--showAllMismatches:on \
--tlsEmulation:on \
--implicitStatic:on \
--trmacros:on \
--panics:on \
"

        case "${__target_os}-${__target_arch}" in
        darwin-amd64)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:clang \
--amd64.MacOS.clang.exe="$__target_compiler" \
--amd64.MacOS.clang.linkerexe="$__target_compiler" \
--cpu:amd64 \
--passC:-fPIC \
"
                ;;
        darwin-arm64)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:clang \
--arm64.MacOS.clang.exe="$__target_compiler" \
--arm64.MacOS.clang.linkerexe="$__target_compiler" \
--cpu:arm64 \
--passC:-fPIC \
"
                ;;
        js-js)
                __arguments="js ${___arguments_nim}"
                ;;
        js-wasm)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--define:emscripten \
"
                ;;
        linux-amd64)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--amd64.linux.gcc.exe:"$__target_compiler" \
--amd64.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:amd64 \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-arm64)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--arm64.linux.gcc.exe:"$__target_compiler" \
--arm64.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:arm64 \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-armel|linux-armle)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--arm.linux.gcc.exe:"$__target_compiler" \
--arm.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:arm \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-armhf)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--arm.linux.gcc.exe:"$__target_compiler" \
--arm.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:arm \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-mips)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--mips.linux.gcc.exe:"$__target_compiler" \
--mips.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:mips \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-mipsle|linux-mipsel)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--mipsel.linux.gcc.exe:"$__target_compiler" \
--mipsel.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:mipsel \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-mips64)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--mips64.linux.gcc.exe:"$__target_compiler" \
--mips64.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:mips64 \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-mips64le|linux-mips64el)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--mips64el.linux.gcc.exe:"$__target_compiler" \
--mips64el.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:mips64el \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-mips64r6)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--mips64.linux.gcc.exe:"$__target_compiler" \
--mips64.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:mips64 \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-mips64r6le|linux-mips64r6el)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--mips64el.linux.gcc.exe:"$__target_compiler" \
--mips64el.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:mips64el \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-powerpc)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--powerpc.linux.gcc.exe:"$__target_compiler" \
--powerpc.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:powerpc \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-ppc64le|linux-ppc64el)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--powerpc64el.linux.gcc.exe:"$__target_compiler" \
--powerpc64el.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:powerpc64el \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        linux-riscv64)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--riscv64.linux.gcc.exe:"$__target_compiler" \
--riscv64.linux.gcc.linkerexe:"$__target_compiler" \
--os:linux \
--cpu:riscv64 \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        windows-amd64)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--amd64.windows.gcc.exe:"$__target_compiler" \
--amd64.windows.gcc.linkerexe:"$__target_compiler" \
--os:windows \
--cpu:amd64 \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        windows-arm64)
                __arguments="\
${___arguments_c} \
${___arguments_nim} \
--cc:gcc \
--arm64.windows.gcc.exe:"$__target_compiler" \
--arm64.windows.gcc.linkerexe:"$__target_compiler" \
--os:windows \
--cpu:arm64 \
--passC:-s --passL:-s \
--passC:-static --passL:-static \
"
                ;;
        *)
                I18N_Build_Failed_Parallel "$__target"
                return 1
                ;;
        esac

        __log="${__dir_log}/bin/${__target}.log"
        case "${__target_os}-${__target_arch}" in
        windows-*)
                __output="${__dir_workspace}/bin/${__target}.exe"
                ;;
        js-wasm)
                __output="${__dir_workspace}/bin/${__target}.wasm"
                ;;
        js-js)
                __output="${__dir_workspace}/bin/${__target}.js"
                ;;
        *)
                __output="${__dir_workspace}/bin/${__target}.elf"
                ;;
        esac


        # NOTE: Nim 2.0.2 has internal issue preventing parallel build. Hence,
        #       we have to disable the Parallel I18N to avoid miscommunications.
        I18N_Build "$__target"
        # I18N_Build_Parallel "$__target"
        FS_Remake_Directory "$__dir_workspace"
        FS_Make_Housing_Directory "$__log"
        FS_Remove_Silently "$__output"
        FS_Remove_Silently "$__log"
        eval "nim ${__arguments} --out:${__output} ${__source}" >> "$__log" 2>&1
        ___process=$?
        if [ $___process -ne 0 ]; then
                I18N_Build_Failed_Parallel "$__target"
                return 1
        fi


        # export target
        __dest="${__dir_output}/$(FS_Get_File "${__output}")"
        FS_Remove_Silently "$__dest"
        FS_Copy_File "$__output" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Build_Failed_Parallel "$__target"
                return 1
        fi

        if [ "${__target_os}-${__target_arch}" = "js-wasm" ]; then
                if [ -f "$(FS_Extension_Remove "${__output}" "*").js" ]; then
                        __dest="$(FS_Extension_Remove "$__dest" "*").js"
                        FS_Remove_Silently "$__dest"
                        FS_Copy_File "$(FS_Extension_Remove "${__output}" "*").js" "$__dest"
                        if [ $? -ne 0 ]; then
                                I18N_Build_Failed_Parallel "$__target"
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


        # validate input
        I18N_Sync_Register "${__target_os}-${__target_arch}"
        if [ $(STRINGS_Is_Empty "$__target_os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__target_arch") -eq 0 ]; then
                I18N_Sync_Register_Skipped_Missing_Target
                continue
        fi

        if [ "${__target_os}-${__target_arch}" = "js-js" ]; then
                __target_compiler="native"
        elif [ $(STRINGS_Is_Empty "$__target_compiler") -ne 0 ]; then
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

        __dir_tag="build-${PROJECT_SKU}_${__target_os}-${__target_arch}"
        __dir_workspace="${__tmp_directory}/${__dir_tag}"
        __dir_log="${__log_directory}/${__dir_tag}"


        # execute
        FS_Append_File "${__parallel_directory}/parallel.txt" "\
${PROJECT_SKU}|${__target_os}|${__target_arch}|${__target_compiler}|${__output_directory}|${__dir_workspace}|${__dir_log}|${__source}
"
done <<EOF
$__build_targets
EOF
IFS="$__old_IFS" && unset __old_IFS


# IMPORTANT: Nim cannot perform parallel build due to internal limitations.
#            Hence, we cannot use 'SYNC_Exec_Parallel' for the time being.
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
