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
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# validate dependency
I18N_Check "TAR"
TAR_Is_Available
if [ $? -ne 0 ]; then
        I18N_Check_Failed
        return 1
fi




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


        FS_Make_Directory "$__line"
done
cd "$PROJECT_PATH_ROOT"




# package build
___artifact_build="artifact-build_${PROJECT_OS}-${PROJECT_ARCH}.tar.gz"
I18N_Archive "$___artifact_build"
FS_Remove_Silently "$___artifact_build"
tar czvf "$___artifact_build" \
        "$PROJECT_PATH_BUILD" \
        "$PROJECT_PATH_LOG" \
        "$PROJECT_PATH_PKG" \
        "$PROJECT_PATH_DOCS"




# package workspace
___artifact_workspace="artifact-workspace_${PROJECT_OS}-${PROJECT_ARCH}.tar.gz"
I18N_Archive "$___artifact_workspace"
FS_Remove_Silently "$___artifact_workspace"
tar czvf "$___artifact_workspace" \
        "$PROJECT_PATH_BIN" \
        "$PROJECT_PATH_LIB" \
        "$PROJECT_PATH_TEMP" \
        "$PROJECT_PATH_RELEASE"




# check existences
I18N_Check "$___artifact_build"
FS_Is_File "$___artifact_build"
if [ $? -ne 0 ]; then
        I18N_Check_Failed
        return 1
fi

I18N_Check "$___artifact_workspace"
FS_Is_File "$___artifact_workspace"
if [ $? -ne 0 ]; then
        I18N_Check_Failed
        return 1
fi




# report status
I18N_Run_Successful
return 0
