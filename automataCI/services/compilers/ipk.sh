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




IPK::create_archive() {
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
        TAR::create_gz "../control.tar.gz" "*"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi


        # package data
        cd "${__directory}/data"
        TAR::create_gz "../data.tar.gz" "*"
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


        # archive into ipk
        __file="package.ipk"
        TAR::create_gz "$__file" "debian-binary control.tar.gz data.tar.gz"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi


        # move to destination
        FS::remove_silently "$__destination"
        FS::move "${__file}.gz" "${__destination}"
        __exit=$?


        # return to current directory
        cd "$__current_path" && unset __current_path


        # report status
        return $__exit
}




IPK::create_control() {
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
        __arch="$(IPK::get_architecture "$__os" "$__arch")"
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




IPK::get_architecture() {
        #___os="$1"
        #___arch="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                printf -- ""
                return 1
        fi


        # report status
        printf -- "%b" "$(STRINGS::to_lowercase "${1}-${2}")"
        return 0
}




IPK::is_available() {
        __os="$1"
        __arch="$2"

        if [ -z "$__os" ] || [ -z "$__arch" ]; then
                return 1
        fi


        # validate dependencies
        TAR::is_available
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




IPK::is_valid() {
        #__target="$1"


        # validate input
        if [ -z "$1" ] || [ -d "$1" ] || [ ! -f "$1" ]; then
                return 1
        fi


        # execute
        if [ "${1##*.}" = "ipk" ]; then
                return 0
        fi


        # return status
        return 1
}
