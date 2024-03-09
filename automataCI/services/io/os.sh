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
OS_Get_Arch() {
        ___output="$(uname -m)"
        ___output="$(printf -- "%b" "$___output" | tr '[:upper:]' '[:lower:]')"
        case "$___output" in
        i686-64)
                export ___output='ia64' # Intel Itanium.
                ;;
        i386|i486|i586|i686)
                export ___output='i386'
                ;;
        x86_64)
                export ___output="amd64"
                ;;
        sun4u)
                export ___output='sparc'
                ;;
        "power macintosh")
                export ___output='powerpc'
                ;;
        ip*)
                export ___output='mips'
                ;;
        *)
                ;;
        esac


        # report status
        printf -- "%b" "$___output"
        return 0
}




OS_Get_CPU() {
        # execute
        ___output=$(getconf _NPROCESSORS_ONLN)
        if [ -z "$___output" ] || [ "$___output" -eq 0 ]; then
                ___output="1"
        fi


        # report status
        printf -- "%b" "$___output"
        return 0
}




OS_Get() {
        # execute
        ___output="$(uname)"
        ___output="$(printf -- "%b" "${___output}" | tr '[:upper:]' '[:lower:]')"
        case "$___output" in
        windows*|ms-dos*)
                ___output='windows'
                ;;
        cygwin*|mingw*|mingw32*|msys*)
                ___output='windows'
                ;;
        *freebsd)
                ___output='freebsd'
                ;;
        dragonfly*)
                ___output='dragonfly'
                ;;
        *)
                ;;
        esac


        # report status
        printf -- "%b" "$___output"
        return 0
}




OS_Is_Command_Available() {
        #___command="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi


        # execute
        if [ ! -z "$(type -t "$1")" ]; then
                return 0
        fi


        # report status
        return 1
}




OS_Is_Run_Simulated() {
        # execute
        if [ ! -z "$PROJECT_SIMULATE_RELEASE_REPO" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




OS_Print_Status() {
        # NOTE: to be scrapped soon!
        __status_mode="$1" && shift 1
        __msg=""
        __color=""

        case "$__status_mode" in
        error)
                __msg="⦗ ERROR ⦘   "
                __color="31"
                ;;
        warning)
                __msg="⦗ WARNING ⦘ "
                __color="33"
                ;;
        info)
                __msg="⦗ INFO ⦘    "
                __color="36"
                ;;
        note)
                __msg="⦗ NOTE ⦘    "
                __color="35"
                ;;
        success)
                __msg="⦗ SUCCESS ⦘ "
                __color="32"
                ;;
        ok)
                __msg="⦗ OK ⦘      "
                __color="36"
                ;;
        done)
                __msg="⦗ DONE ⦘    "
                __color="36"
                ;;
        plain)
                __msg=""
                ;;
        *)
                return 0
                ;;
        esac

        if [ ! -z "$COLORTERM" ] || [ "$TERM" = "xterm-256color" ]; then
                __msg="\033[1;${__color}m${__msg}\033[0;${__color}m${@}\033[0m"
        else
                __msg="${__msg} ${@}"
        fi

        1>&2 printf -- "${__msg}"
        unset __status_mode __msg __color
        return 0
}
