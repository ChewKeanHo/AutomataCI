#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/copyright.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/deb.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/manual.sh"




PACKAGE_Assemble_DEB_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"
        _changelog="$6"


        # validate target before job
        case "$_target_os" in
        android|ios|js|illumos|plan9|wasip1)
                return 10 # not supported in apt ecosystem yet
                ;;
        windows)
                return 10 # not applicable
                ;;
        *)
                ;;
        esac

        case "$_target_arch" in
        avr|wasm)
                return 10 # not applicable
                ;;
        *)
                ;;
        esac

        _gpg_keyring="$PROJECT_SKU"
        _package="$PROJECT_SKU"
        if [ $(FS::is_target_a_source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_library "$_target") -eq 0 ]; then
                # copy main libary
                # TIP: (1) usually is: usr/local/lib
                #      (2) please avoid: lib/, lib{TYPE}/ usr/lib/, and usr/lib{TYPE}/
                _filepath="${_directory}/data/usr/local/lib/${PROJECT_SKU}"
                _filepath="${_filepath}/lib${PROJECT_SKU}.a"
                OS::print_status info "copying ${_target} to ${_filepath}\n"
                FS::make_housing_directory "$_filepath"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS::copy_file "$_target" "$_filepath"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                _gpg_keyring="lib$PROJECT_SKU"
                _package="lib$PROJECT_SKU"
        elif [ $(FS::is_target_a_wasm_js "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_cargo "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_MSI "$_target") -eq 0 ]; then
                return 10 # not applicable
        else
                # copy main program
                # TIP: (1) usually is: usr/local/bin or usr/local/sbin
                #      (2) please avoid: bin/, usr/bin/, sbin/, and usr/sbin/
                _filepath="${_directory}/data/usr/local/bin/${PROJECT_SKU}"

                OS::print_status info "copying $_target to ${_filepath}/\n"
                FS::make_housing_directory "$_filepath"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS::copy_file "$_target" "$_filepath"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # NOTE: REQUIRED file
        OS::print_status info "creating changelog.gz files...\n"
        DEB_Create_Changelog \
                "$_directory" \
                "$_changelog" \
                "$PROJECT_DEBIAN_IS_NATIVE" \
                "$PROJECT_SKU"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # NOTE: REQUIRED file
        OS::print_status info "creating copyright.gz file...\n"
        COPYRIGHT::create_deb \
                "$_directory" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/licenses/deb-copyright" \
                "$PROJECT_DEBIAN_IS_NATIVE" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # NOTE: REQUIRED file
        OS::print_status info "creating man(page) files...\n"
        MANUAL::create_deb \
                "$_directory" \
                "$PROJECT_DEBIAN_IS_NATIVE" \
                "$PROJECT_SKU" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # NOTE: REQUIRED file
        OS::print_status info "creating control/md5sum files...\n"
        DEB_Create_Checksum "$_directory"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # NOTE: OPTIONAL (Comment to turn it off)
        OS::print_status info "creating source.list files...\n"
        DEB_Create_Source_List \
                "$PROJECT_SIMULATE_RELEASE_REPO" \
                "$_directory" \
                "$PROJECT_GPG_ID" \
                "$PROJECT_STATIC_URL" \
                "$PROJECT_REPREPRO_CODENAME" \
                "$PROJECT_DEBIAN_DISTRIBUTION" \
                "$_gpg_keyring"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # WARNING: THIS REQUIRED FILE MUST BE THE LAST ONE
        OS::print_status info "creating control/control file...\n"
        DEB_Create_Control \
                "$_directory" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}" \
                "$_package" \
                "$PROJECT_VERSION" \
                "$_target_arch" \
                "$_target_os" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_PITCH" \
                "$PROJECT_DEBIAN_PRIORITY" \
                "$PROJECT_DEBIAN_SECTION" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/ABSTRACTS.txt"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
