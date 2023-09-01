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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compress/gz.sh"




MANUAL::is_available() {
        GZ::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}




MANUAL::create_deb_manpage() {
        __directory="$1"
        __is_native="$2"
        __sku="$3"
        __name="$4"
        __email="$5"
        __website="$6"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ]; then
                unset __directory \
                        __is_native \
                        __sku \
                        __name \
                        __email \
                        __website
                return 1
        fi

        # check if is the document already injected
        __location="${__directory}/data/usr/local/share/man/man1/${__sku}.1"
        if [ -f "${__location}.gz" ]; then
                unset __location \
                        __directory \
                        __is_native \
                        __sku \
                        __name \
                        __email \
                        __website
                return 0
        fi

        if [ "$__is_native" = "true" ]; then
                __location="${__directory}/data/usr/share/man/man1/${__sku}.1"
                if [ -f "${__location}.gz" ]; then
                        unset __location \
                                __directory \
                                __is_native \
                                __sku \
                                __name \
                                __email \
                                __website
                        return 0
                fi
        fi

        # create manpage
        MANUAL::create_baseline_manpage \
                "$__location" \
                "$__sku" \
                "$__name" \
                "$__email" \
                "$__website"
        __exit=$?
        if [ $__exit -ne 0 ]; then
                __exit=1
        fi

        # report status
        unset __location \
                __directory \
                __is_native \
                __sku \
                __name \
                __email \
                __website
        return $__exit
}




MANUAL::create_rpm_manpage() {
        __directory="$1"
        __sku="$2"
        __name="$3"
        __email="$4"
        __website="$5"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ]; then
                unset __directory \
                        __sku \
                        __name \
                        __email \
                        __website
                return 1
        fi

        # check if is the document already injected
        __location="${__directory}/BUILD/${__sku}.1"
        if [ -f "${__location}.gz" ]; then
                unset __location \
                        __directory \
                        __sku \
                        __name \
                        __email \
                        __website
                return 0
        fi

        # create manpage
        MANUAL::create_baseline_manpage \
                "$__location" \
                "$__sku" \
                "$__name" \
                "$__email" \
                "$__website"
        __exit=$?
        if [ $__exit -ne 0 ]; then
                __exit=1
        fi

        # report status
        unset __location \
                __directory \
                __sku \
                __name \
                __email \
                __website
        return $__exit
}




MANUAL::create_baseline_manpage() {
        __location="$1"
        __sku="$2"
        __name="$3"
        __email="$4"
        __website="$5"

        # validate input
        if [ -z "$__location" ] ||
                [ -d "$__location" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ]; then
                unset __location \
                        __sku \
                        __name \
                        __email \
                        __website
                return 1
        fi

        # create housing directory path
        mkdir -p "${__location%/*}"

        # create basic level 1 man page that instruct users to seek --help
        rm -rf "$__location" &> /dev/null
        printf "\
.\" ${__sku} - Lv1 Manpage
.TH man 1 \"${__sku} man page\"

.SH NAME
${__sku} - Getting help

.SH SYNOPSIS
command: $ ./${__sku} help

.SH DESCRIPTION
This is a backward-compatible auto-generated system-level manual page. To make
sure you get the required and proper assistances from the software, please make
sure you call the command above.

.SH SEE ALSO
Please visit ${__website} for more info.

.SH AUTHORS
Contact: ${__name} <${__email}>
" > "${__location}"

        # gunzip the manual
        GZ::create "$__location"
        __exit=$?
        if [ $__exit -ne 0 ]; then
                __exit=1
        fi

        # report status
        unset __location \
                __sku \
                __name \
                __email \
                __website
        return $__exit
}
