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
OS_Print_Status info "executing tests...\n"
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}"
if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
        OS_Print_Status warning "simulating on-screen unit testing...\n"
        EXIT_CODE=0
else
        CHROME_BIN='/usr/bin/vivaldi' ng test --no-watch --code-coverage
        EXIT_CODE=$?
fi
cd "$__current_path" && unset __current_path




# export report
OS_Print_Status info "exporting coverage report...\n"
FS_Is_Directory "${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}/coverage"
if [ $? -eq 0 ]; then
        LOG_PATH="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/angular-test-report"
        FS_Remove_Silently "$LOG_PATH"
        FS_Make_Housing_Directory "$LOG_PATH"
        FS_Move "${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}/coverage" "$LOG_PATH"
fi




# return status
if [ $EXIT_CODE -ne 0 ]; then
        OS_Print_Status error "test failed.\n"
        return 1
fi

return 0
