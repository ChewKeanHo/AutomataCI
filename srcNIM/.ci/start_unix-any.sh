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
OS::print_status info "checking nim availability...\n"
NIM::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "missing nim compiler.\n"
        return 1
fi


OS::print_status info "activating localized environment...\n"
NIM::activate_local_environment
if [ $? -ne 0 ]; then
        OS::print_status error "activation failed.\n"
        return 1
fi




# execute
OS::print_status info "\n"
OS::print_status note "IMPORTANT NOTICE\n"
OS::print_status note "please perform the following command at your terminal manually:\n"
OS::print_status note "    $ . ${PROJECT_NIM_LOCALIZED}\n"
OS::print_status info "\n"




# report status
return 0
