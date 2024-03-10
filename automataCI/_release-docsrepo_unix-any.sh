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
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Conclude_DOCS() {
        # validate input
        I18N_Check "DOCS"
        FS_Is_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
        if [ $? -ne 0 ]; then
                return 0
        fi

        FS_Is_File "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
        if [ $? -eq 0 ]; then
                I18N_Check_Failed
                return 1
        fi
        FS_Make_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"


        # execute
        I18N_Setup "DOCS"
        GIT_Clone_Repo \
                "$PROJECT_PATH_ROOT" \
                "$PROJECT_PATH_RELEASE" \
                "$PWD" \
                "$PROJECT_DOCS_REPO" \
                "$PROJECT_SIMULATE_RELEASE_REPO" \
                "$PROJECT_DOCS_REPO_DIRECTORY" \
                "$PROJECT_DOCS_REPO_BRANCH"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi


        # export contents
        __staging="${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
        __dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_DOCS_REPO_DIRECTORY}"

        I18N_Export "$__staging"
        FS_Copy_All "${__staging}/" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Export_Failed
                return 1
        fi

        I18N_Commit "DOCS"
        __tag="$(GIT_Get_Latest_Commit_ID)"
        if [ $(STRINGS_Is_Empty "$__tag") -eq 0 ]; then
                I18N_Commit_Failed
                return 1
        fi

        ___current_path="$PWD" && cd "${__dest}"
        GIT_Autonomous_Force_Commit \
                "$__tag" \
                "$PROJECT_DOCS_REPO_KEY" \
                "$PROJECT_DOCS_REPO_BRANCH"
        ___process=$?
        cd "$___current_path" && unset ___current_path

        if [ $___process -ne 0 ]; then
                I18N_Commit_Failed
                return 1
        fi


        # report status
        return 0
}
