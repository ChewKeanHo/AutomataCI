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
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"
. "${LIBS_AUTOMATACI}/services/publishers/homebrew.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Run_HOMEBREW() {
        #___target="$1"
        #___repo="$2"


        # validate input
        HOMEBREW_Is_Valid_Formula "$1"
        if [ $? -ne 0 ]; then
                return 0
        fi

        I18N_Export "$1"
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                I18N_Export_Failed
                return 1
        fi


        # execute
        HOMEBREW_Publish "$1" "${2}/Formula/${PROJECT_SKU}.rb"
        if [ $? -ne 0 ]; then
                I18N_Export_Failed
                return 1
        fi


        # report status
        return 0
}




RELEASE_Conclude_HOMEBREW() {
        #___directory="$1"


        # validate input
        I18N_Commit "HOMEBREW"
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                I18N_Commit_Failed
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                I18N_Commit_Failed
                return 1
        fi


        # execute
        ___current_path="$PWD"
        cd "$1"
        GIT_Autonomous_Commit "${PROJECT_SKU} ${PROJECT_VERSION}"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                I18N_Commit_Failed
                return 1
        fi

        GIT_Pull_To_Latest
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                I18N_Commit_Failed
                return 1
        fi

        GIT_Push "$PROJECT_CHOCOLATEY_REPO_KEY" "$PROJECT_CHOCOLATEY_REPO_BRANCH"
        ___process=$?
        cd "$___current_path" && unset ___current_path
        if [ $___process -ne 0 ]; then
                I18N_Commit_Failed
                return 1
        fi


        # report status
        return 0
}




RELEASE_Setup_HOMEBREW() {
        # clean up base directory
        I18N_Check "HOMEBREW"
        FS_Is_File "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
        if [ $? -eq 0 ]; then
                I18N_Check_Failed
                return 1
        fi
        FS_Make_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"


        # execute
        I18N_Setup "HOMEBREW"
        GIT_Clone_Repo \
                "$PROJECT_PATH_ROOT" \
                "$PROJECT_PATH_RELEASE" \
                "$PWD" \
                "$PROJECT_HOMEBREW_REPO" \
                "$PROJECT_SIMULATE_RELEASE_REPO" \
                "$PROJECT_HOMEBREW_DIRECTORY"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi


        # report status
        return 0
}
