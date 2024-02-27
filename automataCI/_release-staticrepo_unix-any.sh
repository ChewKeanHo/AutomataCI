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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/i18n/translations.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/versioners/git.sh"




RELEASE_Conclude_STATIC_REPO() {
        # validate input
        I18N_Source "GIT COMMIT ID"
        __tag="$(GIT_Get_Latest_Commit_ID)"
        if [ $(STRINGS_Is_Empty "$__tag") -eq 0 ]; then
                I18N_Source_Failed
                return 1
        fi


        # execute
        __current_path="$PWD"
        cd "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_STATIC_REPO_DIRECTORY}"

        ___file="Home.md"
        I18N_Create "$___file"
        FS::write_file "$___file" "\
# ${PROJECT_NAME} Static Distribution Repository

This is a re-purposed repository for housing various distribution ecosystem
such as but not limited to \`.deb\`, \`.rpm\`, \`.flatpak\`, and etc for folks
to \`apt-get install\`, \`yum install\`, or \`flatpak install\`.
"


        I18N_Commit "STATIC REPO"
        GIT_Autonomous_Force_Commit \
                "$__tag" \
                "$PROJECT_STATIC_REPO_KEY" \
                "$PROJECT_STATIC_REPO_BRANCH"
        ___process=$?

        cd "$__current_path" && unset __current_path


        # report status
        if [ $___process -ne 0 ]; then
                I18N_Commit_Failed
                return 1
        fi

        return 0
}




RELEASE_Setup_STATIC_REPO() {
        # clean up base directory
        I18N_Check "STATIC REPO"
        FS::is_file "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
        if [ $? -eq 0 ]; then
                I18N_Check_Failed
                return 1
        fi
        FS::make_directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"


        # execute
        I18N_Setup "STATIC REPO"
        GIT_Clone_Repo \
                "$PROJECT_PATH_ROOT" \
                "$PROJECT_PATH_RELEASE" \
                "$PWD" \
                "$PROJECT_STATIC_REPO" \
                "$PROJECT_SIMULATE_RELEASE_REPO" \
                "$PROJECT_STATIC_REPO_DIRECTORY"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi


        # move existing items to static repo
        __staging="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${PROJECT_PATH_RELEASE}"
        __dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_STATIC_REPO_DIRECTORY}"
        FS::is_directory "$__staging"
        if [ $? -eq 0 ]; then
                I18N_Export "STATIC REPO"
                FS::copy_all "${__staging}/" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Export_Failed
                        return 1
                fi
        fi


        # report status
        return 0
}
