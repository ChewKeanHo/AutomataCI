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
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rust.sh"




# safety checking control surfaces
I18N_Activate_Environment
RUST_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi




# execute
__report_location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/rust-test-report"
__target="$(RUST_Get_Build_Target "$PROJECT_OS" "$PROJECT_ARCH")"
__filename="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
__workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rust-test-${__filename}"


I18N_Prepare "$__report_location"
FS_Remake_Directory "$__report_location"
if [ $? -ne 0 ]; then
        I18N_Prepare_Failed
        return 1
fi
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_RUST}"


I18N_Run_Test_Coverage
RUSTFLAGS="-C instrument-coverage=all" cargo test --verbose --target-dir "$__workspace"
__exit_code=$?
for __file in *.profraw; do
        if [ ! -f "$__file" ]; then
                continue
        fi

        FS_Move "$__file" "$__workspace"
done

if [ $__exit_code -ne 0 ]; then
        cd "$__current_path" && unset __current_path
        I18N_Run_Failed
        return 1
fi


I18N_Processing_Test_Coverage
grcov "$__workspace" \
        --source-dir "${PROJECT_PATH_ROOT}/${PROJECT_RUST}" \
        --binary-path "${__workspace}/debug" \
        --output-types "html" \
        --branch \
        --ignore-not-existing \
        --output-path "$__report_location"
if [ $? -ne 0 ]; then
        cd "$__current_path" && unset __current_path
        I18N_Processing_Failed
        return 1
fi


cd "$__current_path" && unset __current_path




# return status
return 0
