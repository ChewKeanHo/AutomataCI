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




SHASUM_Create_From_File() {
        #___target="$1"
        #___algo="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        case "$2" in
        1|224|256|384|512|512224|512256)
                ;;
        *)
                return 1
                ;;
        esac


        # execute
        OS_Is_Command_Available "shasum"
        if [ $? -eq 0 ]; then
                ___ret="$(shasum -a "$2" "$1")"
                if [ -z "$___ret" ]; then
                        return 1
                fi

                printf "${___ret%% *}"
                unset ___ret
        fi


        # report status
        return 0
}




SHASUM_Is_Available() {
        # execute
        OS_Is_Command_Available "shasum"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}
