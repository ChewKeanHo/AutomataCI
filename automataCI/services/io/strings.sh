#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
STRINGS_Has_Prefix() {
        #___prefix="$1"
        #___content="$2"


        # validate input
        if [ "$(STRINGS_Is_Empty "$1")" -eq 0 ]; then
                return 1
        fi


        # execute
        if [ "${2%"${2#"${1}"*}"}" = "$1" ]; then
                return 0
        fi


        # report status
        return 1
}




STRINGS_Has_Suffix() {
        #___suffix="$1"
        #___content="$2"


        # validate input
        if [ "$(STRINGS_Is_Empty "$1")" -eq 0 ]; then
                return 1
        fi


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




STRINGS_Is_Empty() {
        #___target="$1"


        # execute
        if [ -z "$1" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




STRINGS_Replace_All() {
        #___content="$1"
        #___subject="$2"
        #___replacement="$3"


        # validate input
        if [ "$(STRINGS_Is_Empty "$1")" -eq 0 ]; then
                printf -- ""
                return 1
        fi

        if [ "$(STRINGS_Is_Empty "$2")" -eq 0 ]; then
                printf -- ""
                return 1
        fi

        if [ "$(STRINGS_Is_Empty "$3")" -eq 0 ]; then
                printf -- ""
                return 1
        fi


        # execute
        ___right="$1"
        ___register=""
        while [ -n "$___right" ]; do
                ___left=${___right%%${2}*}

                if [ "$___left" = "$___right" ]; then
                        printf -- "%b" "${___register}${___right}"
                        return 0
                fi

                # replace this occurence
                ___register="${___register}${___left}${3}"
                ___right="${___right#*${2}}"
        done


        # report status
        printf -- "%b" "${___register}"
        return 0
}




STRINGS_To_Lowercase() {
        #___content="$1"


        # execute
        printf -- "%b" "$1" | tr '[:upper:]' '[:lower:]'


        # report status
        return 0
}




STRINGS_To_Titlecase() {
        #___content="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                printf -- ""
                return 1
        fi


        # execute
        ___buffer=""
        ___resevoir="$1"
        ___trigger=0
        while [ -n "$___resevoir" ]; do
                ## extract character
                ___char="$(printf -- "%.1s" "$___resevoir")"
                if [ "$___char" = '\' ]; then
                        ___char="$(printf -- "%.2s" "$___resevoir")"
                fi
                ___resevoir="${___resevoir#*${___char}}"

                ## process character
                if [ $___trigger -eq 0 ]; then
                        ___char="$(printf -- "%s" "$___char" | tr '[:lower:]' '[:upper:]')"
                else
                        ___char="$(printf -- "%s" "$___char" | tr '[:upper:]' '[:lower:]')"
                fi
                ___buffer="${___buffer}${___char}"

                ## set next character action
                case "$___char" in
                " "|"\r"|"\n")
                        ___trigger=0
                        ;;
                *)
                        ___trigger=1
                        ;;
                esac
        done


        # report status
        printf -- "%s" "$___buffer"
        return 0
}




STRINGS_To_Uppercase() {
        #___content="$1"


        # execute
        printf -- "%b" "$1" | tr '[:lower:]' '[:upper:]'


        # report status
        return 0
}




STRINGS_Trim_Whitespace_Left() {
        #___content="$1"


        # execute
        printf -- "%b" "${1#"${1%%[![:space:]]*}"}"


        # report status
        return 0
}




STRINGS_Trim_Whitespace_Right() {
        #___content="$1"


        # execute
        printf -- "%b" "${1%"${1##*[![:space:]]}"}"


        # report status
        return 0
}




STRINGS_Trim_Whitespace() {
        #___content="$1"


        # execute
        ___content="$(STRINGS_Trim_Whitespace_Left "$1")"
        ___content="$(STRINGS_Trim_Whitespace_Right "$___content")"
        printf -- "%b" "$___content"
        unset ___content


        # report status
        return 0
}
