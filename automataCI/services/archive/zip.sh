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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"




ZIP_Create() {
        #___destination="$1"
        #___source="$2"


        # validate input
        ZIP_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        zip -9 -r "$1" $2
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




ZIP_Extract() {
        ___destination="$1"
        ___source="$2"


        # validate input
        OS::is_command_available "unzip"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::is_file "$___source"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::is_file "$___destination"
        if [ $? -eq 0 ]; then
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




ZIP_Is_Available() {
        # execute
        OS::is_command_available "zip"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}
