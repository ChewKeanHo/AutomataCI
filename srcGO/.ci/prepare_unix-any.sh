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
OS::print_status info "go get modules...\n"
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_GO}"
go get .
if [ $? -ne 0 ]; then
        cd "$__current_path" && unset __current_path
        OS::print_status error "go get failed.\n"
        return 1
fi
cd "$__current_path" && unset __current_path




# report status
return 0