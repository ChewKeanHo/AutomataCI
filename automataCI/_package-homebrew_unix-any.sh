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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/archive/tar.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/checksum/shasum.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




PACKAGE::run_homebrew() {
        #__line="$1"


        # parse input
        __line="${1%|*}"

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
        OS::print_status info "checking tar functions availability...\n"
        TAR::is_available
        if [ $? -ne 0 ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi


        # prepare workspace and required values
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/homebrew_${_src}"
        OS::print_status info "creating homebrew source package...\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi


        # copy all complimentary files to the workspace
        OS::print_status info "checking PACKAGE::assemble_homebrew_content function...\n"
        OS::is_command_available "PACKAGE::assemble_homebrew_content"
        if [ $? -ne 0 ]; then
                OS::print_status error "missing PACKAGE::assemble_homebrew_content function.\n"
                return 1
        fi

        OS::print_status info "assembling package files...\n"
        PACKAGE::assemble_homebrew_content \
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


        # check formula.rb is available
        OS::print_status info "checking formula.rb availability...\n"
        FS::is_file "${_src}/formula.rb"
        if [ $? -ne 0 ]; then
                OS-Print-Status error "check failed.\n"
                return 1
        fi


        # archive the assembled payload
        __current_path="$PWD" && cd "$_src"
        OS::print_status info "archiving ${_target_path}.tar.xz\n"
        TAR::create_xz "${_target_path}.tar.xz" "*"
        __exit=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit -ne 0 ]; then
                OS::print_status error "archive failed.\n"
                return 1
        fi


        # sha256 the package
        OS::print_status info "shasum the package with sha256 algorithm...\n"
        __shasum="$(SHASUM::create_file "${_target_path}.tar.xz" "256")"
        if [ -z "$__shasum" ]; then
                OS::print_status error "shasum failed.\n"
                return 1
        fi


        # update the formula.rb script
        OS::print_status info "update given formula.rb file...\n"
        FS::remove_silently "${_target_path}.rb"
        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                __line="$(STRINGS::replace_all \
                        "$__line" \
                        "{{ TARGET_PACKAGE }}" \
                        "${_target_path##*/}.tar.xz" \
                )"

                __line="$(STRINGS::replace_all \
                        "$__line" \
                        "{{ TARGET_SHASUM }}" \
                        "${__shasum}" \
                )"

                FS::append_file "${_target_path}.rb" "${__line}\n"
                if [ $? -ne 0 ]; then
                        IFS="$old_IFS" && unset __line old_IFS
                        OS::print_status error "update failed.\n"
                        return 1
                fi
        done < "${_src}/formula.rb"
        IFS="$old_IFS" && unset line old_IFS


        # report status
        return 0
}
