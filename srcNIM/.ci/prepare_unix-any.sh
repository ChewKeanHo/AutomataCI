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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/nim.sh"




# safety checking control surfaces
OS_Print_Status info "checking nim availability...\n"
NIM_Is_Available
if [ $? -ne 0 ]; then
        OS_Print_Status error "missing nim compiler.\n"
        return 1
fi


OS_Print_Status info "activating local environment...\n"
NIM_Activate_Local_Environment
if [ $? -ne 0 ]; then
        OS_Print_Status error "activation failed.\n"
        return 1
fi




# execute
OS_Print_Status info "refreshing nimble repo list...\n"
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_NIM}"
nimble refresh
if [ $? -ne 0 ]; then
        cd "$__current_path" && unset __current_path
        OS_Print_Status error "refresh failed.\n"
        return 1
fi
cd "$__current_path" && unset __current_path




# report status
return 0
