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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




CREATEREPO_Is_Available() {
        # execute
        OS_Is_Command_Available "createrepo"
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "createrepo_c"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




CREATEREPO_Publish() {
        ___target="$1"
        ___directory="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$__directory") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___target"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS_Copy_File "$__target" "$__directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "createrepo"
        if [ $? -eq 0 ]; then
                createrepo --update "$__directory"
                if [ $? -eq 0 ]; then
                        return 0
                fi
        fi

        OS_Is_Command_Available "createrepo_c"
        if [ $? -eq 0 ]; then
                createrepo_c --update "$__directory"
                if [ $? -eq 0 ]; then
                        return 0
                fi
        fi


        # report status
        return 1
}
