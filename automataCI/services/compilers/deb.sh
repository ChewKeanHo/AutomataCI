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


DEB::create_copyright() {
        __directory="$1"
        __copyright="$2"
        __is_native="$3"
        __sku="$4"
        __name="$5"
        __email="$6"
        __website="$7"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ ! -f "$__copyright" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ]; then
                unset __directory \
                        __copyright \
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
                        __copyright \
                        __is_native \
                        __sku \
                        __name \
                        __email \
                        __website
                return 2
        fi

        if [ "$__is_native" = "true" ]; then
                __location="${__directory}/data/usr/share/doc/${__sku}/copyright"
                if [ -f "$__location" ]; then
                        unset __location \
                                __directory \
                                __copyright \
                                __is_native \
                                __sku \
                                __name \
                                __email \
                                __website
                        return 2
                fi
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

        # append copyright contents into file
        old_IFS="$IFS"
        while IFS="" read -r line || [ -n "$p" ]; do
                printf "$line\n" >> "$__location"
        done < "$__copyright"
        IFS="$old_IFS"
        unset old_IFS line

        # report status
        unset __location \
                __directory \
                __copyright \
                __is_native \
                __sku \
                __name \
                __email \
                __website
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

DEB::create_man_page() {
        __directory="$1"
        __is_native="$2"
        __sku="$3"
        __name="$4"
        __email="$5"
        __website="$6"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__is_native" ] ||
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
        if [ -f "$__location" ] || [ -f "${__location}.gz" ]; then
                unset __location \
                        __directory \
                        __is_native \
                        __sku \
                        __name \
                        __email \
                        __website
                return 2
        fi

        if [ "$__is_native" = "true" ]; then
                __location="${__directory}/data/usr/share/man/man1/${__sku}.1"
                if [ -f "$__location" ] || [ -f "${__location}.gz" ]; then
                        unset __location \
                                __directory \
                                __is_native \
                                __sku \
                                __name \
                                __email \
                                __website
                        return 2
                fi
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
" > "$__location"

        # gunzip the manual
        if [ "$(type -t gzip)" ]; then
                gzip -9 "$__location"
                __exit=$?
        elif [ "$(type -t gunzip)" ]; then
                gunzip -9 "$__location"
                __exit=$?
        else
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
        __filepath="$2"
        __sku="$3"
        __version="$4"
        __arch="$5"
        __name="$6"
        __email="$7"
        __website="$8"
        __pitch="$9"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__filepath" ] ||
                [ ! -f "$__filepath" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__version" ] ||
                [ -z "$__arch" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ] ||
                [ -z "$__pitch" ]; then
                unset __directory \
                        __filepath \
                        __sku \
                        __version \
                        __arch \
                        __name \
                        __email \
                        __website \
                        __pitch
                return 1
        fi

        # check if is the document already injected
        __location="${__directory}/control/control"
        if [ -f "$__location" ]; then
                unset __location \
                        __directory \
                        __filepath \
                        __sku \
                        __version \
                        __arch \
                        __name \
                        __email \
                        __website \
                        __pitch
                return 2
        fi

        # create housing directory path
        mkdir -p "${__location%/*}"

        # generate control file
        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                __key="${__line%%: *}"
                __key="${__key#"${__key%%[![:space:]]*}"}"
                __key="${__key%"${__key##*[![:space:]]}"}"
                __value="${__line##*: }"
                __value="${__value#"${__value%%[![:space:]]*}"}"
                __value="${__value%"${__value##*[![:space:]]}"}"

                case "$__key" in
                Package)
                        if [ "$__value" = "{{ AUTO }}" ]; then
                                __value="$__sku"
                        fi
                        ;;
                Version)
                        if [ "$__value" = "{{ AUTO }}" ]; then
                                __value="$__version"
                        fi
                        ;;
                Architecture)
                        if [ "$__value" = "{{ AUTO }}" ]; then
                                __value="$__arch"
                        fi
                        ;;
                Maintainer)
                        if [ "$__value" = "{{ AUTO }}" ]; then
                                __value="$__name <$__email>"
                        fi
                        ;;
                Installed-Size)
                        if [ "$__value" = "{{ AUTO }}" ]; then
                                __value="$(du -ks "${__directory}/data")"
                                __value="${__value%%/*}"
                                __value="${__value%"${__value##*[![:space:]]}"}"
                        fi
                        ;;
                Homepage)
                        if [ "$__value" = "{{ AUTO }}" ]; then
                                __value="$__website"
                        fi
                        ;;
                Description)
                        if [ "$__value" = "{{ AUTO }}" ]; then
                                __value="$__pitch"
                        fi
                        ;;
                *)
                        printf "$__line\n" >> "$__location"
                        continue
                        ;;
                esac

                printf "$__key: $__value\n" >> "$__location"
        done < "$__filepath"
        IFS="$old_IFS"
        unset old_IFS __line __key __value

        # report status
        unset __location \
                __directory \
                __filepath \
                __sku \
                __version \
                __arch \
                __name \
                __email \
                __website \
                __pitch
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
