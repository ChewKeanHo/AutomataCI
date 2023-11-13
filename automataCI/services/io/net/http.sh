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
HTTP_Download() {
        __method="$1"
        __url="$2"
        __filepath="$3"
        __shasum_type="$4"
        __shasum_value="$5"
        __auth_header="$6"


        # validate input
        if [ -z "$__url" ] || [ -z "$__filepath" ]; then
                return 1
        fi

        if [ -z "$(type -t curl)" ] && [ -z "$(type -t wget)" ]; then
                return 1
        fi

        if [ -z "$__method" ]; then
                __method="GET"
        fi


        # execute
        ## clean up workspace
        rm -rf "$__filepath" &> /dev/null
        mkdir -p "${__filepath%/*}" &> /dev/null

        ## download payload
        if [ ! -z "$__auth_header" ]; then
                if [ ! -z "$(type -t curl)" ]; then
                        curl --location \
                                --header "$__auth_header" \
                                --output "$__filepath" \
                                --request "$__method" \
                                "$__url"
                elif [ ! -z "$(type -t wget)" ]; then
                        wget --max-redirect 16 \
                                --header="$__auth_header" \
                                --output-file"$__filepath" \
                                --method="$__method" \
                                "$__url"
                else
                        return 1
                fi
        else
                if [ ! -z "$(type -t curl)" ]; then
                        curl --location \
                                --output "$__filepath" \
                                --request "$__method" \
                                "$__url"
                elif [ ! -z "$(type -t wget)" ]; then
                        wget --max-redirect 16 \
                                --output-file"$__filepath" \
                                --method="$__method" \
                                "$__url"
                else
                        return 1
                fi
        fi

        if [ ! -f "$__filepath" ]; then
                return 1
        fi

        ## checksum payload
        if [ -z "$__shasum_type" ] || [ -z "$__shasum_value" ]; then
                return 0
        fi

        if [ -z "$(type -t shasum)" ]; then
                return 1
        fi

        case "$__shasum_type" in
        1|224|256|384|512|512224|512256)
                ;;
        *)
                return 1
                ;;
        esac

        __target_shasum="$(shasum -a "$__shasum_type" "$__filepath")"
        __target_shasum="${__target_shasum%% *}"
        if [ ! "$__target_shasum" = "$__shasum_value" ]; then
                return 1
        fi


        # report status
        return 0
}




HTTP_Setup() {
        # validate input
        OS::is_command_available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "curl"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        brew install curl
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
