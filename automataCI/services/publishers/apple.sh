#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




APPLE_Install_DMG() {
        #___target="$1"


        # validate input
        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "hdiutil"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "grep"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "awk"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "cp"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___volume="$(hdiutil attach $1 | grep Volumes | awk '{print $3}')"
        if [ $(STRINGS_Is_Empty "$___volume") -eq 0 ]; then
                return 1
        fi

        cp -rf "$___volume"/*.app /Applications
        ___process=$?
        hdiutil detach "$___volume"
        if [ $___process -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
