#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/nim.sh"




# execute
I18N_Activate_Environment
NIM_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


___source="${PROJECT_PATH_ROOT}/${PROJECT_NIM}"
I18N_Prepare "$___source"
___arguments="\
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
--cpu:${PROJECT_ARCH} \
"

case "$PROJECT_OS" in
darwin)
        ___arguments="${___arguments} --cc:clang --passC:-fPIC"
        ;;
*)
        ___arguments="\
${___arguments} \
--cc:gcc \
--passC:-static --passL:-static \
--os:${PROJECT_OS} \
"
        ;;
esac


I18N_Run_Test
NIM_Run_Test "$___source" "$PROJECT_OS" "$PROJECT_ARCH" "$___arguments"
___process=$?
if [ $___process -ne 0 ] && [ $___process -ne 10 ]; then
        I18N_Run_Failed
        return 1
fi




# return status
return 0
