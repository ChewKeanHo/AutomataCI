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
CheckTarIsAvailable() {
        if [ ! -z "$(type -t tar)" ]; then
                return 0
        fi
        >&2 printf "[ ERROR ] - Missing tar archiver. Please install one.\n"
        return 1
}




CheckXZIsAvailable() {
        if [ ! -z "$(type -t xz)" ]; then
                return 0
        fi
        >&2 printf "[ ERROR ] - Missing xz compressor. Please install one.\n"
        return 1
}




CreateTARXZ() {
        src_path="$1"
        dest_path="$2"
        pwd_path="$PWD"


        # clean up destination path
        mkdir -p "${dest_path%/*}"


        # create tar.xz archive
        cd "$src_path"
        XZ_OPT='-9' tar -cvJf "$dest_path" .
        if [ $? -ne 0 ]; then
                unset dest_path src_path pwd_path
                return 1
        fi
        cd "$pwd_path"

        # successful clean up
        unset dest_path src_path pwd_path
        return 0
}
