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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/chocolatey.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




PACKAGE::run_chocolatey() {
        _dest="$1"
        _target="$2"
        _target_filename="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate input
        OS::print_status info "checking zip functions availability...\n"
        ZIP::is_available
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi


        # prepare workspace and required values
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/choco_${_src}"
        OS::print_status info "creating chocolatey source package...\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi


        # copy all complimentary files to the workspace
        OS::print_status info "checking PACKAGE::assemble_chocolatey_content function...\n"
        OS::is_command_available "PACKAGE::assemble_chocolatey_content"
        if [ $? -ne 0 ]; then
                OS::print_status error "missing PACKAGE::assemble_chocolatey_content function.\n"
                return 1
        fi

        OS::print_status info "assembling package files...\n"
        PACKAGE::assemble_chocolatey_content \
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


        # check nuspec file is available
        OS::print_status info "checking .nuspec metadata file availability...\n"
        __name=""
        for __file in "${_src}/"*.nuspec; do
                FS::is_file "${__file}"
                if [ $? -eq 0 ]; then
                        if [ ! -z "$__name" ]; then
                                OS-Print-Status error "check failed - multiple files.\n"
                                return 1
                        fi

                        __name="${__file##*/}"
                        __name="${__name%.nuspec*}"
                fi
        done

        if [ -z "$__name" ]; then
                OS-Print-Status error "check failed.\n"
                return 1
        fi


        # archive the assembled payload
        __name="${__name}-chocolatey_${PROJECT_VERSION}_${_target_os}-${_target_arch}.nupkg"
        __name="${_dest}/${__name}"
        OS::print_status info "archiving ${__name}\n"
        CHOCOLATEY::archive "$__name" "$_src"
        if [ $__exit -ne 0 ]; then
                OS::print_status error "archive failed.\n"
                return 1
        fi


        # test the package
        OS::print_status info "testing ${__name}\n"
        CHOCOLATEY::is_available
        if [ $? -eq 0 ]; then
                CHOCOLATEY::test "$__name"
                if [ $? -ne 0 ]; then
                        OS::print_status error "test failed.\n"
                        return 1
                fi
        else
                OS::print_status warning "test skipped.\n"
        fi


        # report status
        return 0
}
