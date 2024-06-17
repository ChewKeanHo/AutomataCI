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




GPG_Clear_Sign_File() {
        #___output="$1"
        #___target="$2"
        #___id="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$2") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$3") -eq 0 ]; then
                return 1
        fi

        FS_Is_Target_Exist "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        GPG_Is_Available "$3"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        gpg --armor --clear-sign --local-user "$3" --output "$1" "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GPG_Detach_Sign_File() {
        #___output="$1"
        #___target="$2"
        #___id="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$2") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$3") -eq 0 ]; then
                return 1
        fi

        FS_Is_Target_Exist "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        GPG_Is_Available "$3"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        gpg --armor --detach-sign --local-user "$3" --output "$1" "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GPG_Export_Public_Key() {
        #___destination="$1"
        #___id="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        GPG_Is_Available "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS_Remove_Silently "$1"
        gpg --armor --export "$2" > "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GPG_Export_Public_Keyring() {
        #___destination="$1"
        #___id="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        GPG_Is_Available "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS_Remove_Silently "$1"
        gpg --export "$2" > "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GPG_Is_Available() {
        #___id="$1"


        # execute
        OS_Is_Command_Available "gpg"
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 0
        fi

        gpg --list-key "$1" &> /dev/null
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
