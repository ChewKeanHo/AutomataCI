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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




# execute tech specific CI jobs if available
if [ ! -z "$PROJECT_PYTHON" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/stop_unix-any.sh"
        OS::print_status info "Python technology detected. Parsing job recipe: ${__recipe}\n"

        FS::is_file "$__recipe"
        if [ $? -ne 0 ]; then
                OS::print_status error "Parse failed - missing file.\n"
                return 1
        fi

        . "$__recipe"
        if [ $? -ne 0 ]; then
                return 1
        fi
fi




# report status
return 0
