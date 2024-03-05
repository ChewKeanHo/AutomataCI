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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/nim.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/operators_unix-any.sh"




# safety checking control surfaces
OS_Print_Status info "checking nim availability...\n"
NIM::is_available
if [ $? -ne 0 ]; then
        OS_Print_Status error "missing nim compiler.\n"
        return 1
fi


OS_Print_Status info "activating local environment...\n"
NIM::activate_local_environment
if [ $? -ne 0 ]; then
        OS_Print_Status error "activation failed.\n"
        return 1
fi


OS_Print_Status info "checking BUILD::test function availability...\n"
OS_Is_Command_Available "BUILD::test"
if [ $? -ne 0 ]; then
        OS_Print_Status error "check failed.\n"
        return 1
fi


OS_Print_Status info "prepare nim workspace...\n"
__source="${PROJECT_PATH_ROOT}/${PROJECT_NIM}"
__main="${__source}/${PROJECT_SKU}.nim"

SETTINGS_CC="\
compileToC \
--passC:-Wall --passL:-Wall \
--passC:-Wextra --passL:-Wextra \
--passC:-std=gnu89 --passL:-std=gnu89 \
--passC:-pedantic --passL:-pedantic \
--passC:-Wstrict-prototypes --passL:-Wstrict-prototypes \
--passC:-Wold-style-definition --passL:-Wold-style-definition \
--passC:-Wundef --passL:-Wundef \
--passC:-Wno-trigraphs --passL:-Wno-trigraphs \
--passC:-fno-strict-aliasing --passL:-fno-strict-aliasing \
--passC:-fno-common --passL:-fno-common \
--passC:-fshort-wchar --passL:-fshort-wchar \
--passC:-fstack-protector-all --passL:-fstack-protector-all \
--passC:-Werror-implicit-function-declaration --passL:-Werror-implicit-function-declaration \
--passC:-Wno-format-security --passL:-Wno-format-security \
--passC:-Os --passL:-Os \
--passC:-g0 --passL:-g0 \
--passC:-flto --passL:-flto \
"
SETTINGS_NIM="\
--mm:orc \
--define:release \
--opt:size \
--colors:on \
--styleCheck:off \
--showAllMismatches:on \
--tlsEmulation:on \
--implicitStatic:on \
--trmacros:on \
--panics:on \
"

case "$PROJECT_OS" in
darwin)
        __arguments="\
${SETTINGS_CC} \
${SETTINGS_NIM} \
--cc:clang \
--passC:-fPIC \
--cpu:${PROJECT_ARCH} \
"
        ;;
*)
        __arguments="\
${SETTINGS_CC} \
${SETTINGS_NIM} \
--cc:gcc \
--passC:-static --passL:-static \
--os:${PROJECT_OS} \
--cpu:${PROJECT_ARCH} \
"
        ;;
esac




# checking nim package health
OS_Print_Status info "checking nim package health...\n"
NIM::check_package "$__source"
if [ $? -ne 0 ]; then
        OS_Print_Status error "check failed.\n"
        return 1
fi




# execute
BUILD::test "$PROJECT_NIM" "$PROJECT_OS" "$PROJECT_ARCH" "$__arguments" "nim"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi




# return status
return $EXIT_CODE
