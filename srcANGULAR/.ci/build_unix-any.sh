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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/angular.sh"




# execute
OS::print_status info "executing build...\n"
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}"
ANGULAR::build
EXIT_CODE=$?
cd "$__current_path" && unset __current_path

if [ $EXIT_CODE -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# placeholding docs flag
__file="${PROJECT_SKU}-docs_any-any"
OS::print_status info "building output file: ${__file}\n"
FS::make_directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# return status
return 0
