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
DISK::calculate_size() {
        # __location="$1"


        # validate input
        if [ -z "$1" ] || [ ! -d "$1" ]; then
                return 1
        fi

        DISK::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        __size="$(du -ks "$1")"


        # report status
        if [ $? -ne 0 ]; then
                return 1
        fi

        printf "${__size%%[!0-9]*}"
        return 0
}




DISK::is_available() {
        # execute
        if [ ! -z "$(type -t du)" ]; then
                return 0
        fi


        # report status
        return 1
}
