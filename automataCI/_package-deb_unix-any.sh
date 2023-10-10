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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/deb.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




PACKAGE::run_deb() {
        _dest="$1"
        _target="$2"
        _target_filename="$3"
        _target_os="$4"
        _target_arch="$5"
        _changelog_deb="$6"

        OS::print_status info "checking deb functions availability...\n"
        DEB::is_available "$_target_os" "$_target_arch"
        case $? in
        2)
                OS::print_status warning "DEB is incompatible (OS type). Skipping.\n"
                return 0
                ;;
        3)
                OS::print_status warning "DEB is incompatible (CPU type). Skipping.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status warning "DEB is unavailable. Skipping.\n"
                return 0
                ;;
        esac


        # prepare workspace and required values
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}.deb"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/deb_${_src}"
        OS::print_status info "Creating DEB package...\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "${_src}"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi
        FS::make_directory "${_src}/control"
        FS::make_directory "${_src}/data"


        # execute
        OS::print_status info "checking output file existence...\n"
        FS::is_file "$_target_path"
        if [ $? -eq 0 ]; then
                OS::print_status error "check failed - output exists!\n"
                return 1
        fi

        OS::print_status info "checking PACKAGE::assemble_deb_content function...\n"
        OS::is_command_available "PACKAGE::assemble_deb_content"
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi

        OS::print_status info "assembling package files...\n"
        PACKAGE::assemble_deb_content \
                "$_target" \
                "$_src" \
                "$_target_filename" \
                "$_target_os" \
                "$_target_arch" \
                "$_changelog_deb"
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

        OS::print_status info "checking control/md5sums file...\n"
        FS::is_file "${_src}/control/md5sums"
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi

        OS::print_status info "checking control/control file...\n"
        FS::is_file "${_src}/control/control"
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi

        OS::print_status info "archiving .deb package...\n"
        DEB::create_archive "$_src" "$_target_path"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi


        # report status
        return 0
}
