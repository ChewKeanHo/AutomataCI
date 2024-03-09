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

. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rust.sh"




# execute
I18N_Activate_Environment
RUST_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi




# build output binary file
I18N_Configure_Build_Settings
__target="$(RUST_Get_Build_Target "$PROJECT_OS" "$PROJECT_ARCH")"
__filename="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
__workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rust-${__filename}"
if [ $(STRINGS_Is_Empty "$__target") -eq 0 ]; then
        I18N_Configure_Failed
        return 1
fi




# building target
I18N_Build "$__filename"
FS_Remove_Silently "$__workspace"


__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_RUST}"
cargo build --release --target-dir "$__workspace" --target="$__target"
__exit_code=$?
cd "$__current_path" && unset __current_path
if [ $__exit_code -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi




# exporting executable
___source="${__workspace}/${__target}/release/${PROJECT_SKU}"
___dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}/${PROJECT_SKU}"
I18N_Export "$___source" "$___dest"
FS_Make_Housing_Directory "$___dest"
FS_Remove_Silently "$___dest"
FS_Move "$___source" "$___dest"
if [ $? -ne 0 ]; then
        I18N_Export_Failed
        return 1
fi




# report status
return 0
