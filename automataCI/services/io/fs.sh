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
FS::append_file() {
        # __target="$1"
        # __content="$2"


        # validate target
        if [ ! -z "$1" -a -z "$2" ] || [ -z "$1" ]; then
                return 1
        fi


        # perform file write
        printf -- "%b" "$2" >> "$1"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




FS::copy_all() {
        # __source="$1"
        # __destination="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi


        # execute
        cp -r "${1}"* "${2}/."


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




FS::copy_file() {
        # __source="$1"
        # __destination="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi


        # execute
        cp "$1" "$2"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}




FS::is_directory() {
        # __target="$1"


        # execute
        if [ -z "$1" ]; then
                return 1
        fi


        if [ -d "$1" ]; then
                return 0
        fi

        return 1
}




FS::is_file() {
        # __target="$1"


        # execute
        if [ -z "$1" ]; then
                return 1
        fi

        FS::is_directory "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        if [ -f "$1" ]; then
                return 0
        fi

        return 1
}




FS::is_target_a_library() {
        # __target="$1"


        # execute
        if [ "${1#*-lib}" != "$1" ] ||
                [ "${1#*-libs}" != "$1" ] ||
                [ "${1#*-library}" != "$1" ] ||
                [ "${1#*-libraries}" != "$1" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS::is_target_a_source() {
        # __target="$1"


        # execute
        if [ "${1#*-src}" != "$1" ] || [ "${1#*-source}" != "$1" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS::is_target_a_wasm() {
        # __target="$1"


        # execute
        if [ "${1#*-wasm}" != "$1" ]; then
                printf -- "0"
                return 0
        fi


        # report status
        printf -- "1"
        return 1
}




FS::is_target_a_wasm_js() {
        # __target="$1"


        # execute
        if [ "${1#*-wasm}" == "$1" ]; then
                printf -- "1"
                return 1
        fi

        if [ "${1#*.js}" == "$1" ]; then
                printf -- "1"
                return 1
        fi


        # report status
        printf -- "0"
        return 0
}




FS::is_target_exist() {
        # __target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi


        # perform checking
        if [ -f "$1" ]; then
                return 0
        fi


        # report status
        return 1
}




FS::list_all() {
        # __target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS::is_directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ls -la "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




FS::make_directory() {
        # __target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS::is_directory "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi

        FS::is_target_exist "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # execute
        mkdir -p "$1"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




FS::make_housing_directory() {
        # __target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS::is_directory "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # perform create
        FS::make_directory "${1%/*}"


        # report status
        return $?
}




FS::move() {
        # __source="$1"
        # __destination="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi


        # execute
        mv "$1" "$2"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




FS::remake_directory() {
        # __target="$1"


        # execute
        FS::remove_silently "$1"
        FS::make_directory "$1"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}




FS::remove() {
        # __target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi


        # execute
        rm -rf "$1"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




FS::remove_silently() {
        # __target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 0
        fi


        # execute
        rm -rf "$1" &> /dev/null


        # report status
        return 0
}




FS::rename() {
        #__source="$1"
        #__target="$2"


        # execute
        FS::move "$1" "$2"
        return $?
}




FS::touch_file() {
        # __target="$1"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS::is_file "$1"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        touch "$1"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




FS::write_file() {
        # __target="$1"
        # __content="$2"


        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        FS::is_file "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # perform file write
        printf -- "%b" "$2" >> "$1"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}
