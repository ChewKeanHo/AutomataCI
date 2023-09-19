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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/python.sh"




# safety checking control surfaces
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




# execute
report_location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/python-test-report"
OS::print_status info "preparing report vault: ${report_location}\n"
mkdir -p "$report_location"


OS::print_status info "executing all tests with coverage...\n"
python -m coverage run \
        --data-file="${report_location}/.coverage" \
        -m unittest discover \
        -s "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}" \
        -p '*_test.py'
if [ $? -ne 0 ]; then
        OS::print_status error "test executions failed.\n"
        return 1
fi


OS::print_status info "processing test coverage data to html...\n"
python -m coverage html \
        --data-file="${report_location}/.coverage" \
        --directory="$report_location"
if [ $? -ne 0 ]; then
        OS::print_status error "data processing failed.\n"
        return 1
fi




# return status
return 0
