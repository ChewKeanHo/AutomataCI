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




# (0) initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please source from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/python.sh"




# (1) safety checking control surfaces
OS::print_status info "checking python|python3 availability...\n"
PYTHON::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "missing python|python3 intepreter..\n"
        return 1
fi


OS::print_status info "activating python venv...\n"
PYTHON::activate_venv
if [ $? -ne 0 ]; then
        OS::print_status error "activation failed.\n"
        return 1
fi




# (2) report what to do since AutomataCI is executable, not sourcable
OS::print_status info "\n"
OS::print_status info "IMPORTANT NOTE\n"
OS::print_status info "please perform the following command at your terminal manually:\n"
OS::print_status info "    $ . ${VIRTUAL_ENV}/bin/activate\n"
OS::print_status info "\n"



# (3) report successful status
OS::print_status success "\n\n"
return 0
