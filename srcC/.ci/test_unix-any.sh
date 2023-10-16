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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/operators_unix-any.sh"




# safety checking control surfaces
OS::print_status info "checking BUILD::test function availability...\n"
OS::is_command_available "BUILD::test"
if [ $? -ne 0 ]; then
        OS::print_status error "check failed.\n"
        return 1
fi

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
-static \
"

COMPILER=""

EXIT_CODE=0



# execute
if [ "$PROJECT_OS" = "darwin" ]; then
        BUILD::test \
                "$PROJECT_C" \
                "$PROJECT_OS" \
                "$PROJECT_ARCH" \
                "${SETTINGS_BIN}" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi
else
        BUILD::test \
                "$PROJECT_C" \
                "$PROJECT_OS" \
                "$PROJECT_ARCH" \
                "${SETTINGS_BIN} -pie -fPIE" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi
fi




# return status
return $EXIT_CODE
