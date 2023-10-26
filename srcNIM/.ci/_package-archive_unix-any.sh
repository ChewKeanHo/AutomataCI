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




PACKAGE::assemble_archive_content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # package based on target's nature
        if [ $(FS::is_target_a_source "$_target") -eq 0 ]; then
                _target="${PROJECT_PATH_ROOT}/${PROJECT_NIM}/${PROJECT_SKU}pkg"
                OS::print_status info "copying ${_target} to ${_directory}\n"
                FS::copy_all "$_target" "$_directory"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        elif [ $(FS::is_target_a_docs "$_target") -eq 0 ]; then
                FS::is_directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
                if [ $? -ne 0 ]; then
                        return 10 # not applicable
                fi

                FS::copy_all "${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}/" "$_directory"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        elif [ $(FS::is_target_a_library "$_target") -eq 0 ]; then
                OS::print_status info "copying ${_target} to ${_directory}\n"
                FS::copy_file "$_target" "${_directory}/lib${PROJECT_SKU}.a"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        elif [ $(FS::is_target_a_wasm_js "$_target") -eq 0 ]; then
                return 10 # handled by wasm instead
        elif [ $(FS::is_target_a_wasm "$_target") -eq 0 ]; then
                OS::print_status info "copying ${_target} to ${_directory}\n"
                FS::copy_file "$_target" "$_directory"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS::is_file "${_target%.wasm*}.js"
                if [ $? -eq 0 ]; then
                        OS::print_status info "copying ${_target%.wasm*}.js to ${_directory}\n"
                        FS::copy_file "${_target%.wasm*}.js" "$_directory"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                fi
        elif [ $(FS::is_target_a_chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        else
                case "$_target_os" in
                windows)
                        _dest="${_directory}/${PROJECT_SKU}.exe"
                        ;;
                *)
                        _dest="${_directory}/${PROJECT_SKU}"
                        ;;
                esac

                OS::print_status info "copying ${_target} to ${_dest}\n"
                FS::copy_file "$_target" "$_dest"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # copy user guide
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/docs/USER-GUIDES-EN.pdf"
        OS::print_status info "copying ${_target} to ${_directory}\n"
        FS::copy_file "$_target" "${_directory}/."
        if [ $? -ne 0 ]; then
                return 1
        fi


        # copy license file
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/licenses/LICENSE-EN.pdf"
        OS::print_status info "copying ${_target} to ${_directory}\n"
        FS::copy_file "$_target" "${_directory}/."
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
