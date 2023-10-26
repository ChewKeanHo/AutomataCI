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




# execute
OS::print_status info "executing tests...\n"
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}"
if [ ! -z "$PROJECT_SIMULATE_RELEASE_REPO" ]; then
        OS::print_status warning "simulating on-screen unit testing...\n"
        EXIT_CODE=0
else
        CHROME_BIN='/usr/bin/vivaldi' ng test --no-watch --code-coverage
        EXIT_CODE=$?
fi
cd "$__current_path" && unset __current_path




# export report
OS::print_status info "exporting coverage report...\n"
FS::is_directory "${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}/coverage"
if [ $? -eq 0 ]; then
        LOG_PATH="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/angular-test-report"
        FS::remove_silently "$LOG_PATH"
        FS::make_housing_directory "$LOG_PATH"
        FS::move "${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}/coverage" "$LOG_PATH"
fi




# return status
if [ $EXIT_CODE -ne 0 ]; then
        OS::print_status error "test failed.\n"
        return 1
fi

return 0
