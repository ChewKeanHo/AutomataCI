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
FS::copy_file() {
        __src_path="$1"
        __dest_path="$2"

        cp "$__src_path" "$__dest_path"
        if [ $? -eq 0 ]; then
                unset __src_path __dest_path
                return 0
        fi
        unset __src_path __dest_path
        return 1
}




FS::is_directory() {
        if [ -z "$1" ]; then
                return 1
        fi


        if [ -d "$1" ]; then
                return 0
        fi
        return 1
}




FS::list_all() {
        __target_path="$1"

        FS::is_directory "$__target_path"
        if [ $? -ne 0 ]; then
                unset __target_path
                return 1
        fi

        ls -la "$__target_path"
        unset __target_path
        return 0
}




FS::remove() {
        __target_path="$1"

        rm -rf "$__target_path"
        if [ $? -ne 0 ]; then
                unset __target_path
                return 1
        fi

        unset __target_path
        return 0
}




FS::remove_sliently() {
        __target_path="$1"

        rm -rf "$__target_path" &> /dev/null
        unset __target_path
        return 0
}




FS::rename() {
        __source_path="$1"
        __target_path="$2"

        mv "$__source_path" "$__target_path"
        if [ $? -ne 0 ]; then
                unset __source_path __target_path
                return 1
        fi

        unset __source_path __target_path
        return 0
}




FS::make_directory() {
        __target_path="$1"

        mkdir -p "$__target_path"
        if [ $? -eq 0 ]; then
                unset __target_path
                return 0
        fi

        unset __target_path
        return 1
}




FS::remake_directory() {
        # $1 = target_path

        FS::remove_sliently "$1"
        FS::make_directory "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}
