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
DEB::is_available() {
        __os="$1"
        __arch="$2"

        if [ -z "$__os" ] || [ -z "$__arch" ]; then
                unset __os __arch
                return 1
        fi

        # check compatible target os
        case "$__os" in
        windows|darwin)
                unset __os __arch
                return 2
                ;;
        *)
                ;;
        esac

        # check compatible target cpu architecture
        case "$__arch" in
        any)
                unset __os __arch
                return 3
                ;;
        *)
                ;;
        esac
        unset __os __arch

        # validate dependencies
        if [ -z "$(type -t 'gunzip')" -a -z "$(type -t 'gzip')" ] ||
                [ -z "$(type -t 'tar')" ] ||
                [ -z "$(type -t 'find')" ] ||
                [ -z "$(type -t 'md5sum')" -a -z "$(type -t 'md5')" ] ||
                [ -z "$(type -t 'ar')" ] ||
                [ -z "$(type -t 'du')" ]; then
                return 1
        fi

        # report status
        return 0
}


DEB::create_changelog() {
        __directory="$1"
        __filepath="$2"
        __is_native="$3"
        __sku="$4"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__filepath" ] ||
                [ ! -f "$__filepath" ] ||
                [ -z "$__filepath" ] ||
                [ -z "$__is_native" ] ||
                [ -z "$__sku" ]; then
                unset __directory __filepath __is_native __sku
                return 1
        fi

        # check if is the document already injected
        __location="${__directory}/data/usr/local/share/doc/${__sku}/changelog.gz"
        if [ -f "$__location" ]; then
                unset __location __directory __filepath __is_native __sku
                return 2
        fi

        if [ "$__is_native" = "true" ]; then
                __location="${__directory}/data/usr/share/doc/${__sku}/changelog.gz"
                if [ -f "$__location" ]; then
                        unset __location __directory __filepath __is_native __sku
                        return 2
                fi
        fi

        # create housing directory path
        mkdir -p "${__location%/*}"

        # copy processed file to target location
        cp "$__filepath" "$__location"

        # report status
        unset __location __directory __filepath __is_native __sku
        return 0
}

DEB::create_checksum() {
        __directory="$1"

        # validate input
        if [ -z "$__directory" ] || [ ! -d "$__directory" ]; then
                unset __directory
                return 1
        fi

        # check if is the document already injected
        __location="${__directory}/control/md5sums"
        if [ -f "$__location" ]; then
                unset __location __directory
                return 2
        fi

        # create housing directory path
        mkdir -p "${__location%/*}"

        # checksum
        for __line in $(find "${__directory}/data" -type f); do
                __checksum="$(md5sum "$__line")"
                printf "${__checksum%% *} ${__line##*$__directory/data/}\n" \
                        >> "$__location"
        done

        # report status
        unset __location __checksum __line __directory
        return 0
}

DEB::create_control() {
        __directory="$1"
        __resources="$2"
        __sku="$3"
        __version="$4"
        __arch="$5"
        __name="$6"
        __email="$7"
        __website="$8"
        __pitch="$9"
        __priority="${10}"
        __section="${11}"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__resources" ] ||
                [ ! -d "$__resources" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__version" ] ||
                [ -z "$__arch" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ] ||
                [ -z "$__pitch" ] ||
                [ -z "$__priority" ] ||
                [ -z "$__section" ]; then
                unset __directory \
                        __resources \
                        __sku \
                        __version \
                        __arch \
                        __name \
                        __email \
                        __website \
                        __pitch \
                        __priority \
                        __section
                return 1
        fi

        case "$__priority" in
        required|important|standard|optional|extra)
                ;;
        *)
                unset __directory \
                        __resources \
                        __sku \
                        __version \
                        __arch \
                        __name \
                        __email \
                        __website \
                        __pitch \
                        __priority \
                        __section
                return 1
                ;;
        esac

        # check if is the document already injected
        __location="${__directory}/control/control"
        if [ -f "$__location" ]; then
                unset __location \
                        __directory \
                        __resources \
                        __sku \
                        __version \
                        __arch \
                        __name \
                        __email \
                        __website \
                        __pitch \
                        __priority \
                        __section
                return 2
        fi

        # create housing directory path
        mkdir -p "${__location%/*}"

        # generate control file
        __size="$(du -ks "${__directory}/data")"
        __size="${__size%%/*}"
        __size="${__size%"${__size##*[![:space:]]}"}"
        printf -- "\
Package: $__sku
Version: $__version
Architecture: $__arch
Maintainer: $__name <$__email>
Installed-Size: $__size
Section: $__section
Priority: $__priority
Homepage: $__website
Description: $__pitch
" >> "$__location"

        # append description data file
        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                if [ ! -z "$__line" -a -z "${__line%%#*}" ]; then
                        continue
                fi

                if [ -z "$__line" ]; then
                        __line=" ."
                else
                        __line=" ${__line}"
                fi

                printf -- "%s\n" "$__line" >> "$__location"
        done < "${__resources}/packages/DESCRIPTION.txt"
        IFS="$old_IFS" && unset old_IFS __line

        # report status
        unset __location \
                __size \
                __directory \
                __resources \
                __sku \
                __version \
                __arch \
                __name \
                __email \
                __website \
                __pitch \
                __priority \
                __section
        return 0
}

DEB::create_archive() {
        __directory="$1"
        __destination="$2"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ ! -d "${__directory}/control" ] ||
                [ ! -d "${__directory}/data" ] ||
                [ ! -f "${__directory}/control/control" ]; then
                unset __directory \
                        __destination
                return 1
        fi

        __current_path="$PWD"

        # package control
        cd "${__directory}/control"
        XZ_OPT='-9' tar -cvJf ../control.tar.xz *
        if [ $? -ne 0 ]; then
                cd "$__current_path"
                unset __current_path __directory __destination
                return 1
        fi

        # package data
        cd "${__directory}/data"
        XZ_OPT='-9' tar -cvJf ../data.tar.xz ./[a-z]*
        if [ $? -ne 0 ]; then
                cd "$__current_path"
                unset __current_path __directory __destination
                return 1
        fi

        # generate debian-binary
        cd "${__directory}"
        printf "2.0\n" > "${__directory}/debian-binary"
        if [ $? -ne 0 ]; then
                cd "$__current_path"
                unset __current_path __directory __destination
                return 1
        fi

        # archive into deb
        cd "${__directory}"
        ar r package.deb debian-binary control.tar.xz data.tar.xz
        if [ $? -ne 0 ]; then
                cd "$__current_path"
                unset __current_path __directory __destination
                return 1
        fi

        # move to destination
        rm -f "$__destination" &> /dev/null
        mv package.deb "$__destination"
        __exit=$?

        # report status
        cd "$__current_path"
        unset __current_path __directory __destination
        return $__exit
}
