#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Conclude_PROJECT() {
        # execute
        I18N_Conclude "$PROJECT_VERSION"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Conclude "$PROJECT_VERSION"
                return 0
        fi


        FS_Is_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
        if [ $? -eq 0 ] && [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                # commit single unified repository
                I18N_Commit "$PROJECT_RELEASE_REPO"
                __current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
                GIT_Autonomous_Force_Commit \
                        "$PROJECT_VERSION" \
                        "$PROJECT_RELEASE_REPO_KEY" \
                        "$PROJECT_RELEASE_REPO_BRANCH"
                ___process=$?
                cd "$__current_path" && unset __current_path
                if [ $___process -ne 0 ]; then
                        I18N_Commit_Failed
                        return 1
                fi
        fi


        # report status
        return 0
}




RELEASE_Setup_PROJECT() {
        # execute
        I18N_Setup "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
        if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                I18N_Setup "$PROJECT_RELEASE_REPO"
                GIT_Is_Available
                if [ $? -ne 0 ]; then
                        I18N_Setup_Failed
                        return 1
                fi

                FS_Remove_Silently "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
                __current_path="$PWD" && cd "$PROJECT_PATH_ROOT"
                git clone "$PROJECT_RELEASE_REPO" "$PROJECT_PATH_RELEASE"
                ___process=$?
                cd "$__current_path" && unset __current_path
                if [ $___process -ne 0 ]; then
                        I18N_Setup_Failed
                        return 1
                fi
        else
                FS_Remake_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"
                if [ $? -ne 0 ]; then
                        I18N_Setup_Failed
                        return 1
                fi
        fi


        # report status
        return 0
}
