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
        TAR::create_xz "../control.tar.xz" "*" "0" "0"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi


        # package data
        cd "${__directory}/data"
        TAR::create_xz "../data.tar.xz" "./[a-z]*" "0" "0"
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
        if [ -f "$__location" ]; then
                return 2
        fi

        if [ "$__is_native" = "true" ]; then
                __location="${__directory}/data/usr/share/doc/${__sku}/changelog.gz"
                if [ -f "$__location" ]; then
                        return 2
                fi
        fi


        # create housing directory path
        FS::make_housing_directory "$__location"


        # copy processed file to target location
        FS::copy_file "$__filepath" "$__location"


        # report status
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}




DEB::create_checksum() {
        __directory="$1"


        # validate input
        if [ -z "$__directory" ] || [ ! -d "$__directory" ]; then
                return 1
        fi


        # check if the document has already injected
        __location="${__directory}/control/md5sums"
        if [ -f "$__location" ]; then
                return 2
        fi


        # create housing directory path
        FS::make_housing_directory "$__location"


        # checksum
        for __line in $(find "${__directory}/data" -type f); do
                __checksum="$(MD5::checksum_file "$__line")"
                FS::append_file "$__location" \
                        "${__checksum%% *} ${__line##*${__directory}/data/}\n"
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
                return 1
        fi

        case "$__priority" in
        required|important|standard|optional|extra)
                ;;
        *)
                return 1
                ;;
        esac


        # check if the document has already injected
        __location="${__directory}/control/control"
        if [ -f "$__location" ]; then
                return 2
        fi


        # ensures architecture is the correct value
        case "$__arch" in
        386|486|586|686)
                __arch="i386"
                ;;
        mipsle)
                __arch="mipsel"
                ;;
        mipsr6le)
                __arch="mipsr6el"
                ;;
        mips32le)
                __arch="mips32el"
                ;;
        mipsn32r6le)
                __arch="mipsn32r6el"
                ;;
        mips64le)
                __arch="mips64el"
                ;;
        mips64r6le)
                __arch="mips64r6el"
                ;;
        powerpcle)
                __arch="powerpcel"
                ;;
        ppc64le)
                __arch="ppc64el"
                ;;
        x86_64)
                __arch="amd64"
                ;;
        *)
                ;;
        esac


        # create housing directory path
        FS::make_housing_directory "${__location}"


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
        done < "${__resources}/packages/DESCRIPTION.txt"
        IFS="$old_IFS" && unset old_IFS __line


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
        if [ ! -z "$__is_simulated" ]; then
                return 0
        fi

        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__gpg_id" ] ||
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
        GPG::export_public_keyring "${__directory}/data/$__key" "$__gpg_id"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
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


        # check compatible target os
        case "$__os" in
        windows|darwin)
                return 2
                ;;
        *)
                ;;
        esac


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
