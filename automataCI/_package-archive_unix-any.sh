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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/tar.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/zip.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




PACKAGE::run_archive() {
        _dest="$1"
        _target="$2"
        _target_filename="$3"
        _target_os="$4"
        _target_arch="$5"

        OS::print_status info "checking tar functions availability...\n"
        TAR::is_available
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi

        OS::print_status info "checking zip functions availability...\n"
        ZIP::is_available
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi

        # prepare workspace and required values
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/archive_${_src}"
        OS::print_status info "archiving ${_src} for ${_target_os}-${_target_arch}\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi

        # copy all complimentary files to the workspace
        OS::is_command_available "PACKAGE::assemble_archive_content"
        if [ $? -ne 0 ]; then
                OS::print_status error "missing PACKAGE::assemble_archive_content function.\n"
                return 1
        fi

        OS::print_status info "assembling package files...\n"
        PACKAGE::assemble_archive_content \
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

        # change location into the workspace
        __current_path="$PWD" && cd "$_src"

        # archive the assembled payload
        case "$_target_os" in
        windows)
                _target_path="${_target_path}.zip"
                OS::print_status info "packaging ${_target_path}\n"
                ZIP::create "$_target_path" "*"
                __exit=$?
                ;;
        *)
                _target_path="${_target_path}.tar.xz"
                OS::print_status info "packaging ${_target_path}\n"
                TAR::create_xz "$_target_path" "*"
                __exit=$?
                ;;
        esac

        # head back to current directory
        cd "$__current_path" && unset __current_path

        # report status
        if [ $__exit -eq 0 ]; then
                return 0
        fi

        OS::print_status error "package failed.\n"
        return 1
}
