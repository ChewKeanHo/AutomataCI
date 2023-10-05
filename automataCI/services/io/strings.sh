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




STRINGS::replace_all() {
        #__content="$1"
        #__subject="$2"
        #__replacement="$3"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
                printf -- ""
                return 1
        fi


        # execute
        __right="$1"
        __register=""
        while [ -n "$__right" ]; do
                __left=${__right%%${2}*}

                if [ "$__left" = "$__right" ]; then
                        printf -- "%b" "${__register}${__right}"
                        return 0
                fi

                # replace this occurence
                __register="${__register}${__left}${3}"
                __right="${__right#*${2}}"
        done


        # report status
        printf -- "%b" "${__register}"
        return 0
}




STRINGS::to_lowercase() {
        #__content="$1"

        printf -- "%b" "$1" | tr '[:upper:]' '[:lower:]'
        return 0
}




STRINGS::trim_whitespace_left() {
        #__content="$1"

        printf -- "%b" "${1#"${1%%[![:space:]]*}"}"
        return 0
}




STRINGS::trim_whitespace_right() {
        #__content="$1"

        printf -- "%b" "${1%"${1##*[![:space:]]}"}"
        return 0
}




STRINGS::trim_whitespace() {
        #__content="$1"

        ___content="$(STRINGS::trim_whitespace_left "$1")"
        ___content="$(STRINGS::trim_whitespace_right "$___content")"
        printf -- "%b" "$___content"
        unset ___content
        return 0
}




STRINGS::to_uppercase() {
        #__content="$1"

        printf -- "%b" "$1" | tr '[:lower:]' '[:upper:]'
        return 0
}
