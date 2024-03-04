#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/sync.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/c.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rust.sh"




# safety checking control surfaces
I18N_Status_Print info "activating local environment...\n"
RUST_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Status_Print error "activation failed.\n"
        return 1
fi




# parallel build executables
__output_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
FS_Make_Directory "$__output_directory"


__log_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/rust-build"
FS_Make_Directory "$__log_directory"


__parallel_directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rust-parallel"
FS_Remake_Directory "$__parallel_directory"


SUBROUTINE::build() {
        #__line="$1"


        # parse input
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
        I18N_Status_Print info "building ${__subject} in parallel...\n"
        FS_Remove_Silently "$__workspace"
        __current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_RUST}"

        if [ ! -z "$__linker" ]; then
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
                I18N_Status_Print error "build failed - ${__subject}\n"
                return 1
        fi


        # export target
        FS_Make_Housing_Directory "$__dest"
        if [ -f "${__source}.wasm" ]; then
                FS_Remove_Silently "${__dest%.*}.wasm"
                FS_Move "${__source}.wasm" "${__dest%.*}.wasm"
                if [ $? -ne 0 ]; then
                        I18N_Status_Print error "build failed - ${__subject}\n"
                        return 1
                fi

                if [ -f "${__source}.js" ]; then
                        FS_Remove_Silently "${__dest%.*}.js"
                        FS_Move "${__source}.js" "${__dest%.*}.js"
                        if [ $? -ne 0 ]; then
                                I18N_Status_Print error "build failed - ${__subject}\n"
                                return 1
                        fi
                fi
        elif [ -f "${__source}.exe" ]; then
                FS_Remove_Silently "${__dest%.*}.exe"
                FS_Move "${__source}.exe" "${__dest%.*}.exe"
                if [ $? -ne 0 ]; then
                        I18N_Status_Print error "build failed - ${__subject}\n"
                        return 1
                fi
        else
                FS_Remove_Silently "$__dest"
                FS_Move "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Status_Print error "build failed - ${__subject}\n"
                        return 1
                fi
        fi
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
        __linker="$(C::get_compiler "$__os" "$__arch" "$PROJECT_OS" "$PROJECT_ARCH")"


        # validate input
        I18N_Status_Print info "registering ${__subject} build...\n"
        if [ -z "$__target" ]; then
                I18N_Status_Print warning "register skipped - missing target.\n"
                continue
        fi

        ## NOTE: perform any hard-coded host system restrictions or gatekeeping
        ##       customization adjustments here.
        case "$__arch" in ### adjust by CPU Architecture
        mips|mipsel|mipsle|mips64|mips64el|mips64le)
                I18N_Status_Print warning "register skipped - ${__subject} unsupported.\n"
                continue
                ;;
        ppc64|riscv64)
                I18N_Status_Print warning "register skipped - ${__subject} unsupported.\n"
                continue
                ;;
        wasm)
                __linker=""
                ;;
        *)
                if [ -z "$__linker" ]; then
                        I18N_Status_Print warning "register skipped - missing linker.\n"
                        continue
                fi
                ;;
        esac

        case "$__os" in ### adjust by OS
        js)
                continue
                ;;
        darwin)
                if [ ! "$PROJECT_OS" = "darwin" ]; then
                        I18N_Status_Print warning "register skipped - ${__dest##*/} unsupported.\n"
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
        I18N_Status_Print info "adding rust cross-compiler (${__target})...\n"
        rustup target add "$__target"
        if [ $? -ne 0 ]; then
                I18N_Status_Print error "addition failed.\n"
                return 1
        fi

        FS_Append_File "${__parallel_directory}/parallel.txt" "\
|${__target}|${__filename}|${__workspace}|${__source}|${__dest}|${__linker}|${__log}|
"
done <<EOF
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
EOF
IFS="$__old_IFS" && unset __old_IFS

SYNC_Exec_Parallel "SUBROUTINE::build" "${__parallel_directory}/parallel.txt"
if [ $? -ne 0 ]; then
        return 1
fi




# placeholding source code flag
__file="${PROJECT_SKU}-src_any-any"
I18N_Status_Print info "building placeholder file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        I18N_Status_Print error "build failed.\n"
        return 1
fi




# placeholding homebrew code flag
__file="${PROJECT_SKU}-homebrew_any-any"
I18N_Status_Print info "building placeholder file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        I18N_Status_Print error "build failed.\n"
        return 1
fi




# placeholding chocolatey code flag
__file="${PROJECT_SKU}-chocolatey_any-any"
I18N_Status_Print info "building placeholder file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        I18N_Status_Print error "build failed.\n"
        return 1
fi




# placeholding cargo code flag
__file="${PROJECT_SKU}-cargo_any-any"
I18N_Status_Print info "building placeholder file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        I18N_Status_Print error "build failed.\n"
        return 1
fi




# placeholding msi code flag
__file="${PROJECT_SKU}-msi_any-any"
I18N_Status_Print info "building placeholder file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        I18N_Status_Print error "build failed.\n"
        return 1
fi




# compose documentations




# report status
return 0
