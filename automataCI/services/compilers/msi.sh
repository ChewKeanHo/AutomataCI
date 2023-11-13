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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/microsoft.sh"




MSI_Compile() {
        #__target="$1"
        #__arch="$2"


        # validate input
        MSI_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ -z "$1" ] || [ ! -f "$1" ]; then
                return 1
        fi

        __arch="$(MICROSOFT_Arch_Get "$2")"
        if [ -z "$__arch" ]; then
                return 1
        fi


        # execute
        wixl --verbose --arch "${__arch}" --output "${1%.wxs*}.msi" "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




MSI_Is_Available() {
        # execute
        if [ -z "$(type -t wixl)" ] || [ -z "$(type -t wixl-heat)" ]; then
                return 1
        fi


        # report status
        return 0
}




MSI_Setup() {
        # validate input
        if [ -z "$(type -t brew)" ]; then
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
