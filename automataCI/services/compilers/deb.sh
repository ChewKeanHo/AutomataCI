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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/disk.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/tar.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/ar.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/crypto/gpg.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/checksum/md5.sh"




DEB::create_archive() {
        __directory="$1"
        __destination="$2"


        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ ! -d "${__directory}/control" ] ||
                [ ! -d "${__directory}/data" ] ||
                [ ! -f "${__directory}/control/control" ]; then
                return 1
        fi


        # capture current directory
        __current_path="$PWD"


        # package control
        cd "${__directory}/control"
        TAR::create_xz "../control.tar.xz" "*"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi


        # package data
        cd "${__directory}/data"
        TAR::create_xz "../data.tar.xz" "*"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi


        # generate debian-binary
        cd "${__directory}"
        FS::write_file "${__directory}/debian-binary" "2.0\n"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi


        # archive into deb
        __file="package.deb"
        AR::create "$__file" "debian-binary control.tar.xz data.tar.xz"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi


        # move to destination
        FS::remove_silently "$__destination"
        FS::move "$__file" "$__destination"
        __exit=$?


        # return to current directory
        cd "$__current_path" && unset __current_path


        # report status
        return $__exit
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
                [ -z "$__is_native" ] ||
                [ -z "$__sku" ]; then
                return 1
        fi


        # check if the document has already injected
        __location="${__directory}/data/usr/local/share/doc/${__sku}/changelog.gz"
        if [ "$__is_native" = "true" ]; then
                __location="${__directory}/data/usr/share/doc/${__sku}/changelog.gz"
        fi


        # create housing directory path
        FS::make_housing_directory "$__location"
        FS::remove_silently "$__location"


        # copy processed file to target location
        FS::copy_file "$__filepath" "$__location"


        # report status
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}




DEB::create_checksum() {
        #__directory="$1"


        # validate input
        if [ -z "$1" ] || [ ! -d "$1" ]; then
                return 1
        fi


        # prepare workspace
        __location="${1}/control/md5sums"
        FS::remove_silently "$__location"
        FS::make_housing_directory "$__location"


        # checksum every items
        for __line in $(find "${1}/data" -type f); do
                __checksum="$(MD5::checksum_file "$__line")"
                FS::append_file "$__location" \
                        "${__checksum%% *} ${__line##*${1}/data/}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done


        # report status
        return 0
}




DEB::create_control() {
        __directory="$1"
        __resources="$2"
        __sku="$3"
        __version="$4"
        __arch="$5"
        __os="$6"
        __name="$7"
        __email="$8"
        __website="$9"
        __pitch="${10}"
        __priority="${11}"
        __section="${12}"
        __description_filepath="${13}"


        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__resources" ] ||
                [ ! -d "$__resources" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__version" ] ||
                [ -z "$__arch" ] ||
                [ -z "$__os" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ] ||
                [ -z "$__pitch" ] ||
                [ -z "$__priority" ] ||
                [ -z "$__section" ]; then
                return 1
        fi

        case "$__priority" in
        required|important|standard|optional|extra)
                ;;
        *)
                return 1
                ;;
        esac


        # prepare workspace
        __arch="$(DEB::get_architecture "$__os" "$__arch")"
        __location="${__directory}/control/control"
        FS::make_housing_directory "${__location}"
        FS::remove_silently "${__location}"


        # generate control file
        __size="$(DISK::calculate_size "${__directory}/data")"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::write_file "$__location" "\
Package: $__sku
Version: $__version
Architecture: $__arch
Maintainer: $__name <$__email>
Installed-Size: $__size
Section: $__section
Priority: $__priority
Homepage: $__website
Description: $__pitch
"


        # append description data file
        if [ ! -z "$__description_filepath" ] && [ -f "$__description_filepath" ]; then
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

                        FS::append_file "$__location" "${__line}\n"
                done < "${__description_filepath}"
                IFS="$old_IFS" && unset old_IFS __line
        fi


        # report status
        return 0
}




DEB::create_source_list() {
        __is_simulated="$1"
        __directory="$2"
        __gpg_id="$3"
        __url="$4"
        __codename="$5"
        __distribution="$6"
        __sku="$7"


        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__gpg_id" -a -z "$__is_simulated" ] ||
                [ -z "$__url" ] ||
                [ -z "$__codename" ] ||
                [ -z "$__distribution" ] ||
                [ -z "$__sku" ]; then
                return 1
        fi


        # execute
        __url="${__url}/deb"
        __url="${__url%//deb*}/deb"
        __key="usr/local/share/keyrings/${__sku}-keyring.gpg"
        __filename="${__directory}/data/etc/apt/sources.list.d/${__sku}.list"

        FS::is_file "$__filename"
        if [ $? -eq 0 ]; then
                return 10
        fi

        FS::is_file "${__directory}/data/$__key"
        if [ $? -eq 0 ]; then
                return 1
        fi


        FS::make_housing_directory "$__filename"
        FS::write_file "${__filename}" "\
# WARNING: AUTO-GENERATED - DO NOT EDIT!
deb [signed-by=/${__key}] ${__url} ${__codename} ${__distribution}
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::make_housing_directory "${__directory}/data/$__key"
        if [ ! -z "$__is_simulated" ]; then
                FS::write_file "${__directory}/data/${__key}" ""
        else
                GPG::export_public_keyring "${__directory}/data/${__key}" "$__gpg_id"
        fi


        # report status
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}




DEB::get_architecture() {
        #___os="$1"
        #___arch="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                printf -- ""
                return 1
        fi


        # process os
        case "$1" in
        dragonfly)
                ___output="dragonflybsd"
                ;;
        *)
                ___output="$1"
                ;;
        esac


        # process arch
        case "$2" in
        386|i386|486|i486|586|i586|686|i686)
                ___output="${___output}-i386"
                ;;
        mipsle)
                ___output="${___output}-mipsel"
                ;;
        mipsr6le)
                ___output="${___output}-mipsr6el"
                ;;
        mips32le)
                ___output="${___output}-mips32el"
                ;;
        mips32r6le)
                ___output="${___output}-mips32r6el"
                ;;
        mips64le)
                ___output="${___output}-mips64el"
                ;;
        mips64r6le)
                ___output="${___output}-mips64r6el"
                ;;
        powerpcle)
                ___output="${___output}-powerpcel"
                ;;
        ppc64le)
                ___output="${___output}-ppc64el"
                ;;
        *)
                ___output="${___output}-${2}"
                ;;
        esac


        # report status
        ___output="$(STRINGS::to_lowercase "${___output}")"
        printf -- "%b" "$___output"
        return 0
}




DEB::is_available() {
        __os="$1"
        __arch="$2"

        if [ -z "$__os" ] || [ -z "$__arch" ]; then
                return 1
        fi


        # validate dependencies
        MD5::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        TAR::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        AR::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        DISK::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "find"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # check compatible target cpu architecture
        case "$__arch" in
        any)
                return 3
                ;;
        *)
                ;;
        esac


        # report status
        return 0
}




DEB::is_valid() {
        #__target="$1"


        # validate input
        if [ -z "$1" ] || [ -d "$1" ] || [ ! -f "$1" ]; then
                return 1
        fi


        # execute
        if [ "${1##*.}" = "deb" ]; then
                return 0
        fi


        # return status
        return 1
}
