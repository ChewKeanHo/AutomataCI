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
. "${LIBS_AUTOMATACI}/services/publishers/microsoft.sh"




MSI_Compile() {
        #___target="$1"
        #___arch="$2"


        # validate input
        MSI_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___arch="$(MICROSOFT_Get_Arch "$2")"
        if [ -z "$___arch" ]; then
                return 1
        fi


        # execute
        wixl --verbose --arch "${___arch}" --output "${1%.wxs*}.msi" "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




MSI_Is_Available() {
        # execute
        OS_Is_Command_Available "wixl"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "wixl-heat"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




MSI_Setup() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        MSI_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        brew install msitools
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
