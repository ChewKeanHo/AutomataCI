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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"




ZIP::create() {
        # __destination="$1"
        # __source="$2"


        # validate input
        ZIP::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        zip -9 -r "$1" $2


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




ZIP_Extract() {
        ___destination="$1"
        ___source="$2"


        # validate input
        if [ -z "$(type -t unzip)" ]; then
                return 1
        fi

        if [ ! -f "$___source" ]; then
                return 1
        fi

        if [ -f "$___destination" ]; then
                return 1
        fi


        # extract
        FS::make_directory "$___destination"
        unzip "$___source" -d "$___destination"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




ZIP::is_available() {
        # execute
        if [ ! -z "$(type -t zip)" ]; then
                return 0
        fi

        # report status
        return 1
}
