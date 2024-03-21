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




# execute tech specific CI jobs if available
old_IFS="$IFS"
printf -- "%s" "\
${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}
${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}
${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}
${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}
${PROJECT_PATH_ROOT}/${PROJECT_PATH_LIB}
${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}
${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}
${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}
${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}
" | while IFS="" read -r __line || [ -n "$__line" ]; do
        if [ "$__line" = "${PROJECT_PATH_ROOT}" ]; then
                continue
        fi

        if [ "$__line" = "${PROJECT_PATH_ROOT}/" ]; then
                continue
        fi


        I18N_Purge "$__line"
        FS_Remove_Silently "$__line"
done




# clean archive artifacts
cd "$PROJECT_PATH_ROOT"
rm artifact-*.* &> /dev/null




# report status
I18N_Run_Successful
return 0
