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
STRINGS::trim_whitespace_left() {
        #__content="$1"

        printf "${1#"${1%%[![:space:]]*}"}"
        return 0
}




STRINGS::trim_whitespace_right() {
        #__content="$1"

        printf "${1%"${1##*[![:space:]]}"}"
        return 0
}




STRINGS::trim_whitespace() {
        #__content="$1"

        printf "$(STRINGS::trim_whitespace_right "$(STRINGS::trim_whitespace_left "$1")")"
        return 0
}




STRINGS::has_prefix() {
        #__prefix="$1"
        #__content="$2"

        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        # execute
        if [ "${2%"${2#"${1}"*}"}" = "$1" ]; then
                return 0
        fi

        # report status
        return 1
}




STRINGS::has_suffix() {
        #__suffix="$1"
        #__content="$2"

        # execute
        case "$2" in
        *"$1")
                return 0
                ;;
        *)
                return 1
                ;;
        esac
}
