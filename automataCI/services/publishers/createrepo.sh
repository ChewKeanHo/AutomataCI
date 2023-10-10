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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




CREATEREPO::is_available() {
        # execute
        OS::is_command_available "createrepo"
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS::is_command_available "createrepo_c"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




CREATEREPO::publish() {
        __target="$1"
        __directory="$2"


        # validate input
        if [ -z "$__target" ] ||
                [ -z "$__directory" ] ||
                [ -d "$__target" ] ||
                [ ! -d "$__directory" ]; then
                return 1
        fi


        # execute
        FS::copy_file "$__target" "$__directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "createrepo"
        if [ $? -eq 0 ]; then
                createrepo --update "$__directory"
                if [ $? -eq 0 ]; then
                        return 0
                fi
        fi

        OS::is_command_available "createrepo_c"
        if [ $? -eq 0 ]; then
                createrepo_c --update "$__directory"
                if [ $? -eq 0 ]; then
                        return 0
                fi
        fi


        # report status
        return 1
}
