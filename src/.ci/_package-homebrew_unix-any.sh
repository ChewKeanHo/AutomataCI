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




PACKAGE::assemble_homebrew_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"


        # validate project
        if [ $(FS::is_target_a_source "$__target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_library "$__target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm_js "$__target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_wasm "$__target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS::is_target_a_homebrew "$__target") -eq 0 ]; then
                return 1 # not applicable - should be tech-oriented.
        else
                return 10 # not applicable
        fi


        # report status
        return 0
}
