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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/copyright.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/manual.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rpm.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




PACKAGE::run_rpm() {
        _dest="$1"
        _target="$2"
        _target_filename="$3"
        _target_os="$4"
        _target_arch="$5"

        OS::print_status info "checking rpm functions availability...\n"
        RPM::is_available "$_target_os" "$_target_arch"
        case $? in
        2)
                OS::print_status warning "RPM is incompatible (OS type). Skipping.\n"
                return 0
                ;;
        3)
                OS::print_status warning "RPM is incompatible (CPU type). Skipping.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status warning "RPM is unavailable. Skipping.\n"
                return 0
                ;;
        esac

        OS::print_status info "checking manual docs functions availability...\n"
        MANUAL::is_available
        if [ $? -ne 0 ]; then
                OS::print_status error "checking failed.\n"
                return 1
        fi


        # prepare workspace and required values
        _src="${_target_filename}_${_target_os}-${_target_arch}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rpm_${_src}"
        OS::print_status info "Creating RPM package...\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi
        FS::make_directory "${_src}/BUILD"
        FS::make_directory "${_src}/SPECS"


        # copy all complimentary files to the workspace
        OS::print_status info "assembling package files...\n"
        if [ -z "$(type -t PACKAGE::assemble_rpm_content)" ]; then
                OS::print_status error "missing PACKAGE::assemble_rpm_content function.\n"
                return 1
        fi
        PACKAGE::assemble_rpm_content \
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


        # archive the assembled payload
        OS::print_status info "archiving .rpm package...\n"
        RPM::create_archive "$_src" "$_dest" "$PROJECT_SKU" "$_target_arch"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi


        # report status
        return 0
}
