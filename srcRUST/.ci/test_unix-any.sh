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
OS::print_status info "activating local environment...\n"
RUST_Activate_Local_Environment
if [ $? -ne 0 ]; then
        OS::print_status error "activation failed.\n"
        return 1
fi




# execute
__report_location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/rust-test-report"
__target="$(RUST_Get_Build_Target "$PROJECT_OS" "$PROJECT_ARCH")"
__filename="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
__workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rust-test-${__filename}"


OS::print_status info "preparing report vault: ${__report_location}\n"
FS::remake_directory "$__report_location"
if [ $? -ne 0 ]; then
        OS::print_status error "preparation failed.\n"
        return 1
fi
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_RUST}"


OS::print_status info "executing all tests with coverage...\n"
RUSTFLAGS="-C instrument-coverage=all" cargo test --verbose --target-dir "$__workspace"
__exit_code=$?
for __file in *.profraw; do
        if [ ! -f "$__file" ]; then
                continue
        fi

        FS::move "$__file" "$__workspace"
done

if [ $__exit_code -ne 0 ]; then
        cd "$__current_path" && unset __current_path
        OS::print_status error "test executions failed.\n"
        return 1
fi


OS::print_status info "processing all coverage profile data...\n"
grcov "$__workspace" \
        --source-dir "${PROJECT_PATH_ROOT}/${PROJECT_RUST}" \
        --binary-path "${__workspace}/debug" \
        --output-types "html" \
        --branch \
        --ignore-not-existing \
        --output-path "$__report_location"
if [ $? -ne 0 ]; then
        cd "$__current_path" && unset __current_path
        OS::print_status error "process failed.\n"
        return 1
fi


cd "$__current_path" && unset __current_path




# return status
return 0
