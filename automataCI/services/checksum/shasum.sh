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
SHASUM::create_file() {
        #__target="$1"
        #__algo="$2"


        # validate input
        if [ -z "$1" ] || [ ! -f "$1" ] || [ -z "$2" ]; then
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
        if [ ! -z "$(type -t shasum)" ]; then
                __ret="$(shasum -a "$2" "$1")"
                if [ -z "$__ret" ]; then
                        return 1
                fi

                printf "${__ret%% *}"
                unset __ret
        fi


        # report status
        return 0
}




SHASUM::is_available() {
        # execute
        if [ ! -z "$(type -t shasum)" ]; then
                return 0
        fi


        # report status
        return 1
}
