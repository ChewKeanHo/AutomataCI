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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/go.sh"




# safety checking control surfaces
OS::print_status info "checking go availability...\n"
GO::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "missing go compiler.\n"
        return 1
fi


OS::print_status info "activating local environment...\n"
GO::activate_local_environment
if [ $? -ne 0 ]; then
        OS::print_status error "activation failed.\n"
        return 1
fi




# execute
__report_location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/go-test-report"
__profile_location="${__report_location}/test-profile.txt"
__coverage_filepath="${__report_location}/test-coverage.html"


OS::print_status info "preparing report vault: ${__report_location}\n"
FS::remake_directory "$__report_location"
if [ $? -ne 0 ]; then
        OS::print_status error "preparation failed.\n"
        return 1
fi
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_GO}"


OS::print_status info "executing all tests with coverage...\n"
go test -timeout 14400s \
        -coverprofile "${__profile_location}" \
        -race \
        -v \
        ./...
if [ $? -ne 0 ]; then
        cd "$__current_path" && unset __current_path
        OS::print_status error "test executions failed.\n"
        return 1
fi


OS::print_status info "processing test coverage data to html...\n"
go tool cover -html="${__profile_location}" -o "${__coverage_filepath}"
if [ $? -ne 0 ]; then
        cd "$__current_path" && unset __current_path
        OS::print_status error "data processing failed.\n"
        return 1
fi


cd "$__current_path" && unset __current_path




# return status
return 0