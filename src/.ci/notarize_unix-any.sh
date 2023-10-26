#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/crypto/apple.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/crypto/microsoft.sh"




NOTARY::certify() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS::is_target_a_source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_library "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm_js "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        fi


        # notarize
        case "$_target_os" in
        darwin)
                if [ ! -z "$PROJECT_SIMULATE_RELEASE_REPO" ]; then
                        return 12
                fi

                APPLE::is_available
                if [ $? -ne 0 ]; then
                        return 11
                fi

                _dest="${_target%/*}/${_target_name}-signed_${_target_os}-${_target_arch}"
                APPLE::sign "$_dest" "$_target"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        windows)
                if [ ! -z "$PROJECT_SIMULATE_RELEASE_REPO" ]; then
                        return 12
                fi

                MICROSOFT::is_available
                if [ $? -ne 0 ]; then
                        return 11
                fi

                _dest="${_target%/*}/${_target_name}-signed_${_target_os}-${_target_arch}.exe"
                MICROSOFT::sign \
                        "$_dest" \
                        "$_target" \
                        "$PROJECT_CONTACT_NAME" \
                        "$PROJECT_CONTACT_WEBSITE"
                if [ $? -ne 0 ]; then
                        return 1
                fi
                ;;
        *)
                return 10 # not applicable
                ;;
        esac


        # report status
        return 0
}