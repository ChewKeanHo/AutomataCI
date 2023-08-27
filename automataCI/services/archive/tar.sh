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
TAR::is_available() {
        if [ -z "$(type -t tar)" ]; then
                return 1
        fi
        return 0
}




TARXZ::create() {
        __source="$1"
        __destination="$2"

        # validate input
        if [ -z "$__source" ] ||
                [ -z "$__destination" ] ||
                [ ! -d "$__source" ] ||
                [ -f "$__destination" ] ||
                [ -d "$__destination" ]; then
                unset __source __destination
                return 1
        fi

        # create tar.xz archive
        __current="$PWD"
        cd "$__source"
        XZ_OPT='-9' tar -cvJf "$__destination" .
        __exit=$?
        if [ $__exit -ne 0 ]; then
                $__exit = 1
        fi
        cd "$__current"

        # report status
        unset __source __destination __current
        return $__exit
}




GZ::create() {
        __source="$1"
        __destination="$2"

        # validate input
        if [ -z "$__source" ] ||
                [ -z "$__destination" ] ||
                [ -d "$__source" ] ||
                [ -f "$__destination" ] ||
                [ -d "$__destination" ]; then
                unset __source __destination
                return 1
        fi

        # create .gz compressed target
        tar -czvf "$__destination" "$__source"
        __exit=$?
        if [ $__exit -ne 0 ]; then
                __exit=1
        fi

        # report status
        unset __source __destination
        return $__exit
}
