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




MSI::is_available() {
        # execute
        if [ -z "$(type -t wixl)" ] || [ -z "$(type -t wixl-heat)" ]; then
                return 1
        fi


        # report status
        return 0
}




MSI::setup() {
        # validate input
        if [ -z "$(type -t brew)" ]; then
                return 1
        fi

        MSI::is_available
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        brew install msitools
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
