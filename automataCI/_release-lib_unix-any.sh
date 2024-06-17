#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/archive/zip.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Run_LIBS() {
        #__target="$1"


        # validate input
        if [ $(FS_Is_Target_A_Library "$1") -ne 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_SOURCE_RELEASE_TAG_LATEST") -eq 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_SOURCE_GIT_REMOTE") -eq 0 ]; then
                return 0
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 0
        fi


        # execute
        __branch="v${PROJECT_VERSION}"
        if [ $(FS_Is_Target_A_NPM "$1") -eq 0 ]; then
                if [ $(STRINGS_Is_Empty "$PROJECT_NODE_BRANCH_TAG") -eq 0 ]; then
                        return 0
                fi

                __branch="${__branch}_${PROJECT_NODE_BRANCH_TAG}"
        elif [ $(FS_Is_Target_A_C "$1") -eq 0 ]; then
                if [ $(STRINGS_Is_Empty "$PROJECT_C_BRANCH_TAG") -eq 0 ]; then
                        return 0
                fi

                __branch="${__branch}_${PROJECT_C_BRANCH_TAG}"
        else
                return 0
        fi


        # begin publication
        I18N_Publish "git@$__branch"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Publish "$__branch"
                return 0
        fi


        # create workspace directory
        __workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/release-branch_${__branch}"
        GIT_Setup_Workspace_Bare "$PROJECT_SOURCE_GIT_REMOTE" "$__branch" "$__workspace"
        if [ $? -ne 0 ]; then
                I18N_Publish_Failed
                return 1
        fi


        # unpack package into directory
        if [ $(FS_Is_Target_A_TARGZ "$1") -eq 0 ]; then
                TAR_Extract_GZ "$__workspace" "$1"
        elif [ $(FS_Is_Target_A_TARXZ "$1") -eq 0 ]; then
                TAR_Extract_XZ "$__workspace" "$1"
        elif [ $(FS_Is_Target_A_ZIP "$1") -eq 0 ]; then
                ZIP_Extract "$__workspace" "$1"
        else
                FS_Copy_File "$1" "${__workspace}"
        fi

        if [ $? -ne 0 ]; then
                I18N_Publish_Failed
                return 1
        fi


        # commit release
        __current_path="$PWD" && cd "$__workspace"
        GIT_Autonomous_Commit "$__branch"
        ___process=$?
        cd "$__current_path" && unset __current_path
        if [ $___process -ne 0 ]; then
                I18N_Publish_Failed
                return 1
        fi


        # push to upstream
        GIT_Push_Specific "$__workspace" \
                "$PROJECT_SOURCE_GIT_REMOTE" \
                "$__branch" \
                "$__branch"
        if [ $? -ne 0 ]; then
                I18N_Publish_Failed
                return 1
        fi

        GIT_Push_Specific "$__workspace" \
                "$PROJECT_SOURCE_GIT_REMOTE" \
                "$__branch" \
                "${PROJECT_SOURCE_RELEASE_TAG_LATEST}_${__branch#*_}"
        if [ $? -ne 0 ]; then
                I18N_Publish_Failed
                return 1
        fi


        # report status
        return 0
}
