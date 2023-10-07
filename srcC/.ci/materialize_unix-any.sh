#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/compiler-c_unix-any.sh"




# safety check control surfaces
OS::print_status info "checking BUILD::compile function availability...\n"
OS::is_command_available "BUILD::compile"
if [ $? -ne 0 ]; then
        OS::print_status error "check failed.\n"
        return 1
fi

FS::make_directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"

SETTINGS_BIN="\
-Wall \
-Wextra \
-std=gnu89 \
-pedantic \
-Wstrict-prototypes \
-Wold-style-definition \
-Wundef \
-Wno-trigraphs \
-fno-strict-aliasing \
-fno-common \
-fshort-wchar \
-fstack-protector-all \
-Werror-implicit-function-declaration \
-Wno-format-security \
-Os \
-g0 \
-static \
"

COMPILER=""




# execute
if [ "$PROJECT_OS" = "darwin" ]; then
        BUILD::compile \
                "c_binary" \
                "darwin" \
                "amd64" \
                "automataCI.txt" \
                "${SETTINGS_BIN} -target x86_64-apple-darwin-gcc" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                return 1
        fi

        BUILD::compile \
                "c_library" \
                "darwin" \
                "amd64" \
                "libs/sample/automataCI.txt" \
                "${SETTINGS_BIN} -target x86_64-apple-darwin-gcc -fPIC" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                return 1
        fi
else
        BUILD::compile "c_binary" "linux" "amd64" "automataCI.txt" "$SETTINGS_BIN" "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                return 1
        fi

        BUILD::compile \
                "c_library" \
                "linux" \
                "amd64" \
                "libs/sample/automataCI.txt" \
                "${SETTINGS_BIN} -pie -fPIE" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                return 1
        fi
fi




# exporting executable
__source="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}.elf"
__source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__source}"
__dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}/${PROJECT_SKU}"
OS::print_status info "exporting ${__source} to ${__dest}\n"
FS::make_housing_directory "$__dest"
FS::remove_silently "$__dest"
FS::move "$__source" "$__dest"
if [ $? -ne 0 ]; then
        OS::print_status error "export failed.\n"
        return 1
fi




# exporting library
__source="${PROJECT_SKU}-lib_${PROJECT_OS}-${PROJECT_ARCH}.a"
__source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__source}"
__dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LIB}/lib${PROJECT_SKU}.a"
OS::print_status info "exporting ${__source} to ${__dest}\n"
FS::make_housing_directory "$__dest"
FS::remove_silently "$__dest"
FS::move "$__source" "$__dest"
if [ $? -ne 0 ]; then
        OS::print_status error "export failed.\n"
        return 1
fi




# report status
return 0
