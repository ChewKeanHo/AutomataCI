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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




GPG::detach_sign_file() {
        #__target="$1"
        #__id="$2"

        # validate input
        if [ -z "$1" ] || [ ! -f "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        GPG::is_available "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        gpg --armor --detach-sign --local-user "$2" "$1"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}




GPG::export_public_key() {
        #__destination="$1"
        #__id="$2"

        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        GPG::is_available "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        FS::remove_silently "$1"
        gpg --armor --export "$2" > "$1"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}




GPG::export_public_keyring() {
        #__destination="$1"
        #__id="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        GPG::is_available "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS::remove_silently "$1"
        gpg --export "$2" > "$1"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}




GPG::is_available() {
        #__id="$1"

        if [ -z "$(type -t gpg)" ]; then
                return 1
        fi

        gpg --list-key "$1" &> /dev/null
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}
