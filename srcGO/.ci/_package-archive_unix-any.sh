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
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                _target="${PROJECT_PATH_ROOT}/${PROJECT_GO}/libs"
                OS::print_status info "copying ${_target} to ${_directory}\n"
                FS_Copy_All "$_target" "$_directory"
                if [ $? -ne 0 ]; then
                        OS::print_status error "copy failed."
                        return 1
                fi

                FS_Is_File "${_directory}/go.mod"
                if [ $? -ne 0 ]; then
                        OS::print_status info "creating localized go.mod file...\n"
                        FS_Write_File "${_directory}/go.mod" "\
module ${PROJECT_SKU}

replace ${PROJECT_SKU} => ./
"
                        if [ $? -ne 0 ]; then
                                OS::print_status error "create failed."
                                return 1
                        fi
                fi
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                FS_Is_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
                if [ $? -ne 0 ]; then
                        return 10 # not applicable
                fi

                FS_Copy_All "${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}/" "$_directory"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM_JS "$_target") -eq 0 ]; then
                return 10 # handled by wasm instead
        elif [ $(FS_Is_Target_A_WASM "$_target") -eq 0 ]; then
                OS::print_status info "copying ${_target} to ${_directory}\n"
                FS_Copy_File "$_target" "$_directory"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                FS_Is_File "${_target%.wasm*}.js"
                if [ $? -eq 0 ]; then
                        OS::print_status info "copying ${_target%.wasm*}.js to ${_directory}\n"
                        FS_Copy_File "${_target%.wasm*}.js" "$_directory"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                fi
        elif [ $(FS_Is_Target_A_Chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Homebrew "$_target") -eq 0 ]; then
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
                FS_Copy_File "$_target" "$_dest"
                if [ $? -ne 0 ]; then
                        OS::print_status error "copy failed."
                        return 1
                fi
        fi


        # copy user guide
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/docs/USER-GUIDES-EN.pdf"
        OS::print_status info "copying ${_target} to ${_directory}\n"
        FS_Copy_File "$_target" "${_directory}/."
        if [ $? -ne 0 ]; then
                OS::print_status error "copy failed."
                return 1
        fi


        # copy license file
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/licenses/LICENSE-EN.pdf"
        OS::print_status info "copying ${_target} to ${_directory}\n"
        FS_Copy_File "$_target" "${_directory}/."
        if [ $? -ne 0 ]; then
                OS::print_status error "copy failed."
                return 1
        fi


        # report status
        return 0
}
