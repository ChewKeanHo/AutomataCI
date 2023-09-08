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
MD5::checksum_file() {
        # __target="$1"

        # validate input
        if [ -z "$1" ] || [ ! -f "$1" ]; then
                return 1
        fi

        # execute
        if [ ! -z "$(type -t md5sum)" ]; then
                md5sum "$1"
        elif [ ! -z "$(type -t md5)" ]; then
                md5 "$1"
        fi

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}




MD5::is_available() {
        if [ ! -z "$(type -t md5sum)" ] || [ ! -z "$(type -t md5)" ]; then
                return 0
        fi

        return 1
}
