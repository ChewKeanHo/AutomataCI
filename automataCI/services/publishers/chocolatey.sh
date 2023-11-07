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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/net/http.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/zip.sh"




CHOCOLATEY::is_available() {
        # execute
        OS::is_command_available "choco"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




CHOCOLATEY::is_valid_nupkg() {
        #__target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        if [ ! "${1%.asc*}" = "$1" ]; then
                return 1
        fi


        # execute
        if [ $(FS::is_target_a_chocolatey "$1") -ne 0 ]; then
                return 1
        fi

        if [ $(FS::is_target_a_nupkg "$1") -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHOCOLATEY::archive() {
        #__destination="$1"
        #__source="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        ZIP::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        __current_path="$PWD" && cd "$2"
        ZIP::create "$1" "*"
        __exit=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHOCOLATEY::publish() {
        #__target="$1"
        #__destination="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi


        # execute
        FS::make_housing_directory "$2"
        FS::copy_file "$1" "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




CHOCOLATEY::Setup() {
        return 1 # not supported
}




CHOCOLATEY::test() {
        #__target="$1"


        # validate input
        if [ -z "$1" ] || [ ! -f "$1" ]; then
                return 1
        fi

        CHOCOLATEY::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        __name="${1##*/}"
        __name="${__name%%-chocolatey*}"


        # test install
        __current_path="$PWD"
        cd "${1%/*}"
        choco install "${1##*/}" --debug --verbose --force --source .
        __exit=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit -ne 0 ]; then
                return 1
        fi


        # test uninstall
        __current_path="$PWD"
        cd "${1%/*}"
        choco uninstall "${1##*/}" --debug --verbose --force --source .
        __exit=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
