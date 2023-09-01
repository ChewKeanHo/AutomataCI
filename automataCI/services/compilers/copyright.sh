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
COPYRIGHT::create_deb() {
        __directory="$1"
        __manual_file="$2"
        __is_native="$3"
        __sku="$4"
        __name="$5"
        __email="$6"
        __website="$7"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__manual_file" ] ||
                [ ! -f "$__manual_file" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ]; then
                unset __directory \
                        __manual_file \
                        __is_native \
                        __sku \
                        __name \
                        __email \
                        __website
                return 1
        fi

        # checck if is the document already injected
        __location="${__directory}/data/usr/local/share/doc/${__sku}/copyright"
        if [ -f "$__location" ]; then
                unset __location \
                        __directory \
                        __manual_file \
                        __is_native \
                        __sku \
                        __name \
                        __email \
                        __website
                return 0
        fi

        if [ "$__is_native" = "true" ]; then
                __location="${__directory}/data/usr/share/doc/${__sku}/copyright"
                if [ -f "$__location" ]; then
                        unset __location \
                                __directory \
                                __manual_file \
                                __is_native \
                                __sku \
                                __name \
                                __email \
                                __website
                        return 0
                fi
        fi

        # create baseline
        COPYRIGHT::create_baseline_deb \
                "$__location" \
                "$__manual_file" \
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
                __manual_file \
                __is_native \
                __sku \
                __name \
                __email \
                __website
        return $__exit
}

COPYRIGHT::create_rpm() {
        __directory="$1"
        __manual_file="$2"
        __sku="$3"
        __name="$4"
        __email="$5"
        __website="$6"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__manual_file" ] ||
                [ ! -f "$__manual_file" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ]; then
                unset __directory \
                        __manual_file \
                        __sku \
                        __name \
                        __email \
                        __website
                return 1
        fi

        # checck if is the document already injected
        __location="${__directory}/BUILD/copyright"
        if [ -f "$__location" ]; then
                unset __location \
                        __directory \
                        __manual_file \
                        __sku \
                        __name \
                        __email \
                        __website
                return 0
        fi

        # create baseline
        COPYRIGHT::create_baseline_deb \
                "$__location" \
                "$__manual_file" \
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
                __manual_file \
                __sku \
                __name \
                __email \
                __website
        return $__exit
}

COPYRIGHT::create_baseline_deb() {
        __location="$1"
        __manual_file="$2"
        __sku="$3"
        __name="$4"
        __email="$5"
        __website="$6"

        # validate input
        if [ -z "$__location" ] ||
                [ -d "$__location" ] ||
                [ -z "$__manual_file" ] ||
                [ ! -f "$__manual_file" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ]; then
                unset __location \
                        __manual_file \
                        __sku \
                        __name \
                        __email \
                        __website
                return 1
        fi

        # create housing directory path
        mkdir -p "${__location%/*}"

        # create copyright stanza header
        printf "\
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${__sku}
Upstream-Contact: ${__name} <${__email}>
Source: ${__website}

" > "${__location}"

        # append manually facilitated copyright contents
        __old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                printf "$__line\n" >> "$__location"
        done < "$__manual_file"
        IFS="$__old_IFS" && unset __old_IFS __line

        # report status
        unset __location \
                __manual_file \
                __sku \
                __name \
                __email \
                __website
        return 0
}