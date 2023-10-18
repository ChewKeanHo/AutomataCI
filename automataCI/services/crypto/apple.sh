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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




APPLE::sign() {
        #__destination="$1"
        #__file="$2"


        # validate input
        APPLE::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ -z "$1" ] || [ -z "$2" ] || [ ! -f "$2" ]; then
                return 1
        fi


        # execute
        codesign --force --options runtime --deep --sign "$APPLE_DEVELOPER_ID" "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ditto -c -k --keepParent "$2" "${2}.zip"
        if [ $? -ne 0 ]; then
                return 1
        fi

        xcrun notarytool \
                submit \
                "${2}.zip" \
                --keychain-profile "$APPLE_KEYCHAIN_PROFILE" \
                --wait
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::remove_silently "${2}.zip"

        xcrun stapler staple "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::move "$2" "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




APPLE::is_available() {
        # execute
        if [ -z "$(type -t codesign)" ]; then
                return 1
        fi

        if [ -z "$(type -t ditto)" ]; then
                return 1
        fi

        if [ -z "$(type -t xcrun)" ]; then
                return 1
        fi

        if [ -z "$APPLE_DEVELOPER_ID" ]; then
                return 1
        fi

        if [ -z "$APPLE_KEYCHAIN_PROFILE" ]; then
                return 1
        fi


        # report status
        return 0
}
