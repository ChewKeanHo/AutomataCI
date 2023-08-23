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
TARXZ::is_available() {
        if [ -z "$(type -t tar)" ]; then
                return 1
        fi

        if [ -z "$(type -t xz)" ]; then
                return 1
        fi

        return 0
}



TARXZ::create() {
        __src_path="$1"
        __dest_path="$2"
        __pwd_path="$PWD"


        # create tar.xz archive
        cd "$__src_path"
        XZ_OPT='-9' tar -cvJf "$__dest_path" .
        if [ $? -ne 0 ]; then
                unset __src_path __dest_path __pwd_path
                return 1
        fi
        cd "$__pwd_path"


        # successful clean up
        unset __src_path __dest_path __pwd_path
        return 0
}
