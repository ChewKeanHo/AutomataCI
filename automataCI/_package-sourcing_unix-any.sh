#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




# source from baseline
tech_list="\
${PROJECT_PATH_SOURCE:-none}
${PROJECT_ANGULAR:-none}
${PROJECT_C:-none}
${PROJECT_GO:-none}
${PROJECT_NIM:-none}
${PROJECT_PYTHON:-none}
${PROJECT_RESEARCH:-none}
${PROJECT_RUST:-none}
"

old_IFS="$IFS"
while IFS="" read -r tech || [ -n "$tech" ]; do
        # validate input
        if [ $(STRINGS_Is_Empty "$tech") -eq 0 ] ||
                [ "$(STRINGS_To_Uppercase "$tech")" = "NONE" ]; then
                continue
        fi


        # execute
        package_fx="${PROJECT_PATH_ROOT}/${tech}/${PROJECT_PATH_CI}/package_unix-any.sh"
        FS_Is_File "$package_fx"
        if [ $? -eq 0 ]; then
                I18N_Source "$package_fx"
                . "$package_fx"
                if [ $? -ne 0 ]; then
                        I18N_Source_Failed
                        return 1
                fi
        fi
done <<EOF
$tech_list
EOF
IFS="$old_IFS" && unset old_IFS




# report status
return 0
