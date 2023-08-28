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
GZ::is_available() {
        if [ ! -z "$(type -t gzip)" ]; then
                return 0
        elif [ ! -z "$(type -t gunzip)" ]; then
                return 0
        else
                return 1
        fi
}




GZ::create() {
        __source="$1"

        # validate input
        GZ::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ -z "$__source" ] || [ -d "$__source" ]; then
                unset __source
                return 1
        fi
        __source="${__source%.gz}"

        # create .gz compressed target
        if [ ! -z "$(type -t gzip)" ]; then
                gzip -9 $__source
                __exit=$?
        elif [ ! -z "$(type -t gunzip)" ]; then
                gunzip -9 $__source
                __exit=$?
        else
                __exit=1
        fi
        if [ $__exit -ne 0 ]; then
                __exit=1
        fi

        # report status
        unset __source
        return $__exit
}
