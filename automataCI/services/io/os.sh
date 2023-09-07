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
OS::is_command_available() {
        # __command="$1"

        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        # execute
        if [ ! -z "$(type -t "$1")" ]; then
                return 0
        fi
        return 1
}




OS::print_status() {
        __status_mode="$1" && shift 1
        __msg=""
        __stop_color="\033[0m"

        case "$__status_mode" in
        error)
                __msg="[ ERROR   ] ${@}"
                __start_color="\e[91m"
                ;;
        warning)
                __msg="[ WARNING ] ${@}"
                __start_color="\e[93m"
                ;;
        info)
                __msg="[ INFO    ] ${@}"
                __start_color="\e[96m"
                ;;
        success)
                __msg="[ SUCCESS ] ${@}"
                __start_color="\e[92m"
                ;;
        ok)
                __msg="[ INFO    ] == OK =="
                __start_color="\e[96m"
                ;;
        plain)
                __msg="$@"
                ;;
        *)
                return 0
                ;;
        esac


        if [ ! -z "$COLORTERM" ]; then
                if [ "$COLORTERM" = truecolor ] || [ "$COLORTERM" = 24bit ]; then
                        __msg="${__start_color}${__msg}${__stop_color}"
                fi
        fi


        1>&2 printf "${__msg}"
        unset __status_mode __msg __start_color __stop_color
        return 0
}
