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
. "${LIBS_AUTOMATACI}/services/io/net/http.sh"
. "${LIBS_AUTOMATACI}/services/archive/zip.sh"




CHOCOLATEY_Is_Available() {
        # execute
        OS_Is_Command_Available "choco"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




CHOCOLATEY_Is_Valid_Nupkg() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        if [ ! "${1%.asc*}" = "$1" ]; then
                return 1
        fi


        # execute
        if [ $(FS_Is_Target_A_Chocolatey "$1") -ne 0 ]; then
                return 1
        fi

        if [ $(FS_Is_Target_A_Nupkg "$1") -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHOCOLATEY_Archive() {
        #___destination="$1"
        #___source="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        ZIP_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___current_path="$PWD" && cd "$2"
        ZIP_Create "$1" "."
        ___process=$?
        cd "$___current_path" && unset ___current_path
        if [ $___process -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHOCOLATEY_Publish() {
        #___target="$1"
        #___destination="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi


        # execute
        FS_Make_Housing_Directory "$2"
        FS_Copy_File "$1" "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHOCOLATEY_Setup() {
        return 1 # not supported
}




CHOCOLATEY_Test() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        CHOCOLATEY_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___name="${1##*/}"
        ___name="${___name%%-chocolatey*}"


        # test install
        ___current_path="$PWD"
        cd "${1%/*}"
        choco install "${1##*/}" --debug --verbose --force --source .
        ___process=$?
        cd "$___current_path" && unset ___current_path
        if [ $___process -ne 0 ]; then
                return 1
        fi


        # test uninstall
        ___current_path="$PWD"
        cd "${1%/*}"
        choco uninstall "${1##*/}" --debug --verbose --force --source .
        ___process=$?
        cd "$___current_path" && unset ___current_path
        if [ $___process -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
