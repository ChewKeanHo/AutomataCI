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
ZIP::is_available() {
        if [ ! -z "$(type -t zip)" ]; then
                return 0
        fi
        return 1
}




ZIP::create() {
        __src_path="$1"
        __dest_path="$2"
        __pwd_path="$PWD"


        # check commmand availability
        ZIP::is_available
        if [ $? -ne 0 ]; then
                unset __dest_path __src_path __pwd_path
                return 1
        fi


        # archive now
        cd "$__src_path"
        zip -9 -r "$__dest_path" .
        if [ $? -ne 0 ]; then
                cd "$__pwd_path"
                unset __dest_path __src_path __pwd_path
                return 1
        fi
        cd "$__pwd_path"


        # successful clean up
        unset __dest_path __src_path __pwd_path
        return 0
}