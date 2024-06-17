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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
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
        if [ $(STRINGS_Is_Empty "$PROJECT_DOCS_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi


        # execute
        I18N_Publish "DOCS"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Conclude "DOCS"
                return 0
        fi

        FS_Is_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
        if [ $? -ne 0 ]; then
                return 0
        fi

        FS_Is_File "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
        if [ $? -eq 0 ]; then
                I18N_Publish_Failed
                return 1
        fi

        FS_Make_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"

        I18N_Setup "DOCS"
        __directory_name="x_docsrepo"
        GIT_Clone_Repo \
                "$PROJECT_PATH_ROOT" \
                "$PROJECT_PATH_RELEASE" \
                "$PWD" \
                "$PROJECT_DOCS_REPO" \
                "$PROJECT_SIMULATE_RUN" \
                "$__directory_name" \
                "$PROJECT_DOCS_REPO_BRANCH"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi


        # export contents
        __staging="${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
        __dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${__directory_name}"

        I18N_Export "$__staging"
        FS_Copy_All "${__staging}/" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Export_Failed
                FS_Remove_Silently "$__dest"
                return 1
        fi

        __tag="$(GIT_Get_Latest_Commit_ID)"
        I18N_Commit "$__tag"
        if [ $(STRINGS_Is_Empty "$__tag") -eq 0 ]; then
                I18N_Commit_Failed
                FS_Remove_Silently "$__dest"
                return 1
        fi

        __current_path="$PWD" && cd "$__dest"
        GIT_Autonomous_Force_Commit \
                "$__tag" \
                "$PROJECT_DOCS_REPO_KEY" \
                "$PROJECT_DOCS_REPO_BRANCH"
        ___process=$?
        cd "$__current_path" && unset __current_path

        if [ $___process -ne 0 ]; then
                I18N_Commit_Failed
                FS_Remove_Silently "$__dest"
                return 1
        fi

        FS_Remove_Silently "$__dest"


        # report status
        return 0
}
