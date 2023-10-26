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




PACKAGE::assemble_flatpak_content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate target before job
        case "$_target_arch" in
        avr)
                return 10 # not applicable
                ;;
        *)
                ;;
        esac

        if [ $(FS::is_target_a_source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_library "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm_js "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ ! "$__target_os" = "linux" ]; then
                return 10 # not applicable
        fi


        # copy main program
        _target="$1"
        _filepath="${_directory}/${PROJECT_SKU}"
        OS::print_status info "copying ${_target} to ${_filepath}\n"
        FS::copy_file "$_target" "$_filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # copy icon.svg
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/icons/icon.svg"
        _filepath="${_directory}/icon.svg"
        OS::print_status info "copying ${_target} to ${_filepath}\n"
        FS::copy_file "$_target" "$_filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # copy icon-48x48.png
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/icons/icon-48x48.png"
        _filepath="${_directory}/icon-48x48.png"
        OS::print_status info "copying ${_target} to ${_filepath}\n"
        FS::copy_file "$_target" "$_filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # copy icon-128x128.png
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/icons/icon-128x128.png"
        _filepath="${_directory}/icon-128x128.png"
        OS::print_status info "copying ${_target} to ${_filepath}\n"
        FS::copy_file "$_target" "$_filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # OPTIONAL (overrides): copy manifest.yml or manifest.json
        # OPTIONAL (overrides): copy appdata.xml


        # report status
        return 0
}
