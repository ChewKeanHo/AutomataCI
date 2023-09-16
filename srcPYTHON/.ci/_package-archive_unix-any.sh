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




PACKAGE::assemble_archive_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"

        # package based on target's nature
        FS::is_target_a_source "$__target"
        if [ $? -eq 0 ]; then
                # it's a source code target
                PYTHON::clean_artifact "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/"
                FS::copy_all "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/Libs/" "${__directory}"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                return 0
        else
                # it's a binary target
                case "$__target_os" in
                windows)
                        __dest="${__directory}/${PROJECT_SKU}.exe"
                        ;;
                *)
                        __dest="${__directory}/${PROJECT_SKU}"
                        ;;
                esac

                OS::print_status info "copying $__target to $__dest\n"
                FS::copy_file "$__target" "${__dest}"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        # copy user guide
        __target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/docs/USER-GUIDES-EN.pdf"
        OS::print_status info "copying $__target to $__directory\n"
        FS::copy_file "$__target" "${__directory}/."
        if [ $? -ne 0 ]; then
                return 1
        fi

        # copy license file
        __target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/licenses/LICENSE-EN.pdf"
        OS::print_status info "copying $__target to $__directory\n"
        FS::copy_file "$__target" "${__directory}/."
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}
