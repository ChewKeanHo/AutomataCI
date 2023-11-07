#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




DOTNET::get_path_bin() {
        # execute
        printf -- "%b" "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/dotnet-engine/bin"


        # report status
        return 0
}




DOTNET::get_path_root() {
        # execute
        printf -- "%b" "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_DOTNET_ENGINE}"


        # report status
        return 0
}




DOTNET::is_available() {
        # execute
        if [ -f "$(DOTNET::get_path_root)/dotnet" ]; then
                return 0
        fi


        # report status
        return 1
}




DOTNET::setup() {
        # validate input
        DOTNET::is_available
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        DOTNET_CLI_TELEMETRY_OPTOUT=1 \
        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/dotnet-install.sh" \
                --channel STS \
                --install-dir "$(DOTNET::get_path_root)"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
