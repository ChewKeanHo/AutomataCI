#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/os.sh"




ANGULAR_Build() {
        # validate input
        ANGULAR_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ng build
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




ANGULAR_Is_Available() {
        # execute
        OS_Is_Command_Available "npm"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "ng"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




ANGULAR_Setup() {
        # validate input
        ANGULAR_Is_Available
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




ANGULAR_Test() {
        # validate input
        ANGULAR_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ng test --no-watch --code-coverage
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
