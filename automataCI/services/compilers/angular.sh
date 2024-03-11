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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"




ANGULAR::build() {
        # validate input
        ANGULAR::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ng build
        if [ $? -ne 0 ]; then
                return 1
        fi


        # return status
        return 0
}




ANGULAR::is_available() {
        if [ -z "$(type -t npm)" ]; then
                return 1
        fi

        if [ -z "$(type -t ng)" ]; then
                return 1
        fi

        return 0
}




ANGULAR_Setup() {
        # validate input
        ANGULAR::is_available
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "npm"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        npm install -g @angular/cli
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
