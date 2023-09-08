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




# (0) initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




PACKAGE::assemble_flatpak_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"

        # validate target before job
        FS::is_target_a_source "$__target"
        if [ $? -eq 0 ]; then
                return 10
        fi

        # copy main program
        __target="$1"
        __filepath="${__directory}/${PROJECT_SKU}"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # copy icon.svg
        __target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/icons/icon.svg"
        __filepath="${__directory}/icon.svg"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # copy icon-48x48.png
        __target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/icons/icon-48x48.png"
        __filepath="${__directory}/icon-48x48.png"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # copy icon-128x128.png
        __target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/icons/icon-128x128.png"
        __filepath="${__directory}/icon-128x128.png"
        OS::print_status info "copying $__target to ${__filepath}\n"
        FS::copy_file "$__target" "$__filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # OPTIONAL (overrides): copy manifest.yml or manifest.json
        # OPTIONAL (overrides): copy appdata.xml

        # report status
        return 0
}
