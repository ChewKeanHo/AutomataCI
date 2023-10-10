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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"




XZ::create() {
        __source="$1"


        # validate input
        XZ::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ -z "$__source" ] || [ -d "$__source" ]; then
                unset __source
                return 1
        fi
        __source="${__source%.xz}"


        # create .gz compressed target
        xz -9 --compress "$__source"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




XZ::is_available() {
        # execute
        OS::is_command_available "xz"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}
