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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rust.sh"




# safety checking control surfaces
OS_Print_Status info "activating local environment...\n"
RUST_Activate_Local_Environment
if [ $? -ne 0 ]; then
        OS_Print_Status error "activation failed.\n"
        return 1
fi




# build output binary file
OS_Print_Status info "configuring build settings...\n"
__target="$(RUST_Get_Build_Target "$PROJECT_OS" "$PROJECT_ARCH")"
__filename="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
__workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rust-${__filename}"

if [ -z "$__target" ]; then
        OS_Print_Status error "configure failed.\n"
        return 1
fi




# building target
OS_Print_Status info "building ${__filename}...\n"
FS_Remove_Silently "${__workspace}"

__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_RUST}"
cargo build --release --target-dir "$__workspace" --target="$__target"
__exit_code=$?
cd "$__current_path" && unset __current_path
if [ $__exit_code -ne 0 ]; then
        OS_Print_Status error "build failed.\n"
        return 1
fi




# exporting executable
__source="${__workspace}/${__target}/release/${PROJECT_SKU}"
__dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}/${PROJECT_SKU}"
OS_Print_Status info "exporting ${__source} to ${__dest}\n"
FS_Make_Housing_Directory "$__dest"
FS_Remove_Silently "$__dest"
FS_Move "$__source" "$__dest"
if [ $? -ne 0 ]; then
        OS_Print_Status error "export failed.\n"
        return 1
fi




# report status
return 0
