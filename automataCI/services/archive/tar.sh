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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compress/gz.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compress/xz.sh"




TAR::is_available() {
        # execute
        if [ -z "$(type -t tar)" ]; then
                return 1
        fi


        # report status
        return 0
}




TAR::create() {
        #__destination="$1"
        #__source="$2"
        #__owner="$3"
        #__group="$4"


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


        # create tar archive
        if [ ! -z "$3" -a ! -z "$4" ]; then
                tar --numeric-owner --group="$4" --owner="$3" -cvf "$1" $2
                if [ $? -ne 0 ]; then
                        return 1
                fi
        else
                tar -cvf "$1" $2
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # report status
        return 0
}




TAR::create_gz() {
        #__destination="$1"
        #__source="$2"
        #__owner="$3"
        #__group="$4"


        # validate input
        if [ -z "$2" ] || [ -z "$1" ]; then
                return 1
        fi

        if [ -e "$1" ]; then
                return 1
        fi


        # create tar archive
        TAR::create "${1%.gz*}" "$2" "$3" "$4"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # compress archive
        GZ_Create "${1%.gz*}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




TAR::create_xz() {
        #__destination="$1"
        #__source="$2"
        #__owner="$3"
        #__group="$4"


        # validate input
        if [ -z "$2" ] || [ -z "$1" ]; then
                return 1
        fi

        if [ -e "$1" ]; then
                return 1
        fi

        XZ_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # create tar archive
        TAR::create "${1%.xz*}" "$2" "$3" "$4"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # compress archive
        XZ_Create "${1%%.xz*}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
