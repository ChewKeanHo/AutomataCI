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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




MD5_Create_From_File() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        OS_Is_Command_Available "md5sum"
        if [ $? -eq 0 ]; then
                ___value="$(md5sum "$1")"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        OS_Is_Command_Available "md5"
        if [ $? -eq 0 ]; then
                ___value="$(md5 "$1")"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        if [ $(STRINGS_Is_Empty "$___value") -eq 0 ]; then
                return 1
        fi


        # report status
        printf -- "%s" "${___value%% *}"
        return 0
}




MD5_Is_Available() {
        # execute
        OS_Is_Command_Available "md5sum"
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "md5"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}
