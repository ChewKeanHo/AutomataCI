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




GIT::is_available() {
        OS::is_command_available "git"
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}




GIT::clone() {
        #__url="$1"
        #__name="$2"

        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        GIT::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ ! -z "$2" ]; then
                if [ -f "$2" ]; then
                        return 1
                fi

                if [ -d "$2" ]; then
                        return 2
                fi
        fi

        # execute
        if [ ! -z "$2" ]; then
                git clone "$1" "$2"
        else
                git clone "$1"
        fi

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}
