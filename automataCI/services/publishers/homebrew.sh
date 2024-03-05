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




HOMEBREW_Is_Valid_Formula() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        if [ $(FS_Is_Target_A_Homebrew "$1") -ne 0 ]; then
                return 1
        fi

        if [ ! "${1%.asc*}" = "$1" ]; then
                return 1
        fi


        # execute
        if [ ! "${1%.rb*}" = "$1" ]; then
                return 0
        fi


        # report status
        return 1
}




HOMEBREW_Publish() {
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




HOMEBREW_Setup() {
        # validate input
        OS_Is_Command_Available "curl"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "brew"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ $? -ne 0 ]; then
                return 1
        fi

        case "$PROJECT_OS" in
        linux)
                ___location="/home/linuxbrew/.linuxbrew/bin/brew"
                ;;
        darwin)
                ___location="/usr/local/bin/brew"
                ;;
        *)
                return 1
                ;;
        esac

        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                if [ "$___line" = "eval \"\$(${___location} shellenv)\"" ]; then
                        unset ___location
                        break
                fi
        done < "${HOME}/.bash_profile"

        printf -- "eval \"\$(${___location} shellenv)\"" >> "${HOME}/.bash_profile"
        if [ $? -ne 0 ]; then
                return 1
        fi
        eval "$(${___location} shellenv)"

        OS_Is_Command_Available "brew"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}
