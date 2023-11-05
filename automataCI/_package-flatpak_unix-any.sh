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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/flatpak.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




PACKAGE::run_flatpak() {
        #__line="$1"


        # parse input
        __line="${1%|*}"

        _repo="${__line##*|}"
        __line="${__line%|*}"

        _target_arch="${__line##*|}"
        __line="${__line%|*}"

        _target_os="${__line##*|}"
        __line="${__line%|*}"

        _target_filename="${__line##*|}"
        __line="${__line%|*}"

        _target="${__line##*|}"
        __line="${__line%|*}"

        _dest="${__line##*|}"


        # validate input
        OS::print_status info "checking FLATPAK functions availability...\n"
        FLATPAK::is_available "$_target_os" "$_target_arch"
        case $? in
        2)
                OS::print_status warning "FLATPAK is incompatible (OS type). Skipping.\n"
                return 0
                ;;
        3)
                OS::print_status warning "FLATPAK is incompatible (CPU type). Skipping.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status warning "FLATPAK is unavailable. Skipping.\n"
                return 0
                ;;
        esac


        # prepare workspace and required values
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}.flatpak"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/flatpak_${_src}"
        OS::print_status info "Creating FLATPAK package...\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "${_src}"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi

        OS::print_status info "checking output file existence...\n"
        if [ -f "$_target_path" ]; then
                OS::print_status error "check failed - output exists!\n"
                return 1
        fi


        # copy all complimentary files to the workspace
        OS::print_status info "assembling package files...\n"
        if [ -z "$(type -t PACKAGE::assemble_flatpak_content)" ]; then
                OS::print_status error "missing PACKAGE::assemble_flatpak_content function.\n"
                return 1
        fi
        PACKAGE::assemble_flatpak_content \
                "$_target" \
                "$_src" \
                "$_target_filename" \
                "$_target_os" \
                "$_target_arch"
        case $? in
        10)
                FS::remove_silently "$_src"
                OS::print_status warning "packaging is not required. Skipping process.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status error "assembly failed.\n"
                return 1
                ;;
        esac


        # generate required files
        OS::print_status info "creating manifest file...\n"
        FLATPAK::create_manifest \
                "$_src" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}" \
                "$PROJECT_APP_ID" \
                "$PROJECT_SKU" \
                "$_target_arch" \
                "$PROJECT_FLATPAK_RUNTIME" \
                "$PROJECT_FLATPAK_RUNTIME_VERSION" \
                "$PROJECT_FLATPAK_SDK"
        case $? in
        2)
                OS::print_status info "manual injection detected.\n"
                ;;
        0)
                ;;
        *)
                OS::print_status error "create failed.\n"
                return 1
                ;;
        esac

        OS::print_status info "creating AppInfo XML file...\n"
        FLATPAK::create_appinfo \
                "$_src" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        case $? in
        2)
                OS::print_status info "manual injection detected.\n"
                ;;
        0)
                ;;
        *)
                OS::print_status error "create failed.\n"
                return 1
                ;;
        esac


        # archive the assembled payload
        OS::print_status info "archiving .flatpak package...\n"
        FLATPAK::create_archive \
                "$_src" \
                "$_target_path" \
                "$_repo" \
                "$PROJECT_APP_ID" \
                "$PROJECT_GPG_ID"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi


        # report status
        return 0
}
