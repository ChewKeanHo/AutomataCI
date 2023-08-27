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
        __source="$1"
        __destination="$2"

        # validate input
        if [ -z "$__source" ] || [ -z "$__destination" ]; then
                unset __source __destination
                return 1
        fi

        # perform copying
        cp "$__source" "$__destination"
        if [ $? -eq 0 ]; then
                unset __source __destination
                return 0
        fi

        # report status
        unset __source __destination
        return 1
}




FS::is_directory() {
        __subject="$1"

        if [ -z "$__subject" ]; then
                unset __subject
                return 1
        fi


        if [ -d "$__subject" ]; then
                unset __subject
                return 0
        fi

        return 1
}




FS::list_all() {
        __target="$1"

        # validate target
        if [ -z "$__target" ]; then
                unset __target
                return 1
        fi

        # perform listing
        FS::is_directory "$__target"
        if [ $? -ne 0 ]; then
                unset __target
                return 1
        fi

        ls -la "$__target"
        unset __target
        return 0
}




FS::remove() {
        __target="$1"

        # validate target
        if [ -z "$__target" ]; then
                unset __target
        fi

        # perform remove
        rm -rf "$__target"
        __exit=$?
        unset __target
        if [ $__exit -ne 0 ]; then
                __exit=1
        fi
        return $__exit
}




FS::remove_sliently() {
        __target="$1"

        # validate target
        if [ -z "$__target" ]; then
                unset __target
        fi

        # perform remove
        rm -rf "$__target" &> /dev/null
        unset __target
        return 0
}




FS::rename() {
        __source="$1"
        __target="$2"

        # validate input
        if [ -z "$__source" ] ||
                [ -z "$__target" ] ||
                [ ! -d "$__source" ] ||
                [ ! -f "$__source" ] ||
                [ -d "$__target" ] ||
                [ -f "$__target" ]; then
                unset __source __target
                return 1
        fi

        # perform rename
        mv "$__source" "$__target"
        __exit=$?
        if [ $__exit -eq 0 ]; then
                __exit=0
        else
                __exit=1
        fi

        # report status
        unset __source __target
        return $__exit
}




FS::make_directory() {
        __target="$1"

        # validate target
        if [ -z "$__target" ] || [ -d "$__target" ] || [ -f "$__target" ]; then
                unset __target
                return 1
        fi

        # perform create
        mkdir -p "$__target"
        __exit=$?
        unset __target

        # report status
        if [ $__exit -eq 0 ]; then
                return 0
        fi
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
