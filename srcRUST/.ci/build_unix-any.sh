#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
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

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/sync.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/c.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rust.sh"




# execute
I18N_Activate_Environment
RUST_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


__output_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
FS_Make_Directory "$__output_directory"


__log_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/rust-build"
FS_Make_Directory "$__log_directory"


__parallel_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rust-parallel"
FS_Remake_Directory "$__parallel_directory"


__build_targets="\
linux|amd64|.elf
linux|arm64|.elf
linux|armel|.elf
linux|mips|.elf
linux|mipsle|.elf
linux|mips64|.elf
linux|mips64le|.elf
linux|ppc64|.elf
linux|ppc64le|.elf
linux|riscv64|.elf
linux|s390x|.elf
darwin|amd64|.elf
darwin|arm64|.elf
windows|amd64|.exe
js|wasm|.wasm
wasip1|wasm|.wasm
"


__placeholders="\
${PROJECT_SKU}-src_any-any
${PROJECT_SKU}-homebrew_any-any
${PROJECT_SKU}-chocolatey_any-any
${PROJECT_SKU}-cargo_any-any
${PROJECT_SKU}-msi_any-any
"


SUBROUTINE_Build() {
        #__line="$1"


        # parse input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 0
        fi
        __line="${1%|*}"

        __log="${__line##*|}"
        __line="${__line%|*}"

        __linker="${__line##*|}"
        __line="${__line%|*}"

        __dest="${__line##*|}"
        __line="${__line%|*}"

        __source="${__line##*|}"
        __line="${__line%|*}"

        __workspace="${__line##*|}"
        __line="${__line%|*}"

        __filename="${__line##*|}"
        __line="${__line%|*}"

        __target="${__line##*|}"
        __line="${__line%|*}"

        __subject="${__dest##*/}"


        # building target
        I18N_Build_Parallel "$__subject"
        FS_Remove_Silently "$__workspace"
        __current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_RUST}"

        if [ $(STRINGS_Is_Empty "$__linker") -ne 0 ]; then
                cargo build \
                        --release \
                        --target-dir "$__workspace" \
                        --target="$__target" \
                        --config "target.${__target}.linker=\"${__linker}\"" &> "$__log"
        else
                cargo build \
                        --release \
                        --target-dir "$__workspace" \
                        --target="$__target" &> "$__log"
        fi

        __exit_code=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit_code -ne 0 ]; then
                I18N_Build_Failed_Parallel "$__subject"
                return 1
        fi


        # export target
        FS_Make_Housing_Directory "$__dest"
        if [ -f "${__source}.wasm" ]; then
                __dest="$(FS_Extension_Remove "$__dest" ".wasm").wasm"
                FS_Remove_Silently "$__dest"
                FS_Move "${__source}.wasm" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Build_Failed_Parallel "$__subject"
                        return 1
                fi

                if [ -f "${__source}.js" ]; then
                        __dest="$(FS_Extension_Remove "$__dest" ".js").js"
                        FS_Remove_Silently "$__dest"
                        FS_Move "${__source}.js" "$__dest"
                        if [ $? -ne 0 ]; then
                                I18N_Build_Failed_Parallel "$__subject"
                                return 1
                        fi
                fi
        elif [ -f "${__source}.exe" ]; then
                __dest="$(FS_Extension_Remove "$__dest" ".exe").exe"
                FS_Remove_Silently "$__dest"
                FS_Move "${__source}.exe" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Build_Failed_Parallel "$__subject"
                        return 1
                fi
        else
                FS_Remove_Silently "$__dest"
                FS_Move "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Build_Failed_Parallel "$__subject"
                        return 1
                fi
        fi


        # report status
        return 0
}




## register targets and execute parallel build
old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        # parse target data
        __extension="${__line##*|}"
        __line="${__line%|*}"

        __arch="${__line##*|}"
        __line="${__line%|*}"

        __os="${__line}"


        # generate input
        __target="$(RUST_Get_Build_Target "$__os" "$__arch")"
        __filename="${PROJECT_SKU}_${__os}-${__arch}"
        __workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rust-${__filename}"
        __source="${__workspace}/${__target}/release/${PROJECT_SKU}"
        __dest="${__output_directory}/${__filename}${__extension}"
        __subject="${__filename}${__extension}"
        __log="${__log_directory}/rust-${__filename}.txt"
        __linker="$(C_Get_Compiler "$__os" "$__arch" "$PROJECT_OS" "$PROJECT_ARCH")"


        # validate input
        I18N_Sync_Register "$__subject"
        if [ $(STRINGS_Is_Empty "$__target") -eq 0 ]; then
                I18N_Sync_Register_Skipped_Missing_Target
                continue
        fi

        ## NOTE: perform any hard-coded host system restrictions or gatekeeping
        ##       customization adjustments here.
        case "$__arch" in ### filter by CPU Architecture
        mips|mipsel|mipsle|mips64|mips64el|mips64le)
                I18N_Sync_Register_Skipped_Unsupported
                continue
                ;;
        ppc64|riscv64)
                I18N_Sync_Register_Skipped_Unsupported
                continue
                ;;
        wasm)
                __linker=""
                ;;
        *)
                if [ $(STRINGS_Is_Empty "$__linker") -eq 0 ]; then
                        I18N_Sync_Register_Skipped_Missing_Linker
                        continue
                fi
                ;;
        esac

        case "$__os" in ### filter by OS
        js)
                continue
                ;;
        darwin)
                if [ ! "$PROJECT_OS" = "darwin" ]; then
                        I18N_Sync_Register_Skipped_Unsupported
                        continue
                fi
                ;;
        fuchsia)
                __linker=""
                ;;
        *)
                ;;
        esac


        # execute
        I18N_Import_Compiler "(RUST) ${__target}"
        rustup target add "$__target"
        if [ $? -ne 0 ]; then
                I18N_Import_Failed
                return 1
        fi

        FS_Append_File "${__parallel_directory}/parallel.txt" "\
|${__target}|${__filename}|${__workspace}|${__source}|${__dest}|${__linker}|${__log}|
"
done <<EOF
$__build_targets
EOF
IFS="$__old_IFS" && unset __old_IFS

SYNC_Exec_Parallel \
        "SUBROUTINE_Build" \
        "${__parallel_directory}/parallel.txt" \
        "${__parallel_directory}"
if [ $? -ne 0 ]; then
        return 1
fi




# placeholding flag files
old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        __file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__line}"
        I18N_Build "$__file"
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
