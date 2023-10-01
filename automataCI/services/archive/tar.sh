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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compress/xz.sh"




TAR::is_available() {
        if [ -z "$(type -t tar)" ]; then
                return 1
        fi

        return 0
}




TAR::create_xz() {
        # __destination="$1"
        # __source="$2"




        # validate input
        if [ -z "$2" ] || [ -z "$1" ]; then
                return 1
        fi

        if [ -e "$1" ]; then
                return 1
        fi

        TAR::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        XZ::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # create tar archive
        tar -cvf "${1%%.xz*}" $2
        if [ $? -ne 0 ]; then
                return 1
        fi


        # compress archive
        XZ::create "${1%%.xz*}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}
