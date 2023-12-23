#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/python.sh"




# safety checking control surfaces
OS::print_status info "checking python|python3 availability...\n"
PYTHON_Is_Available
if [ $? -ne 0 ]; then
        OS::print_status error "missing python|python3 intepreter.\n"
        return 1
fi




# execute
OS::print_status info "setup python venv...\n"
PYTHON_Setup_VENV
if [ $? -ne 0 ]; then
        OS::print_status error "setup failed.\n"
        return 1
fi




# report status
return 0
