#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




# define operating variables
FLATPAK_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/flatpak"




RELEASE_Conclude_FLATPAK() {
        #__repo_directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_FLATPAK_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        elif [ $(STRINGS_Is_Empty "$PROJECT_FLATPAK_REPO") -eq 0 ] &&
                [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -eq 0 ]; then
                return 0 # single file bundles only
        elif [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                return 0 # do nothing - single unified repository will take over later
        fi

        case "$(STRINGS_To_Lowercase "$PROJECT_RELEASE_REPO_TYPE")" in
        local)
                return 0 # do nothing
                ;;
        *)
                # it's a git repository
                ;;
        esac


        # execute
        I18N_Conclude "FLATPAK"
        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 0 # no repository setup during package job
        fi

        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Conclude "FLATPAK"
                return 0
        fi


        # commit the git repository
        __current_path="$PWD" && cd "$1"
        GIT_Pull_To_Latest
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                I18N_Conclude_Failed
                return 1
        fi

        GIT_Autonomous_Commit "${PROJECT_SKU} ${PROJECT_VERSION}"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                I18N_Conclude_Failed
                return 1
        fi

        GIT_Push "$PROJECT_FLATPAK_REPO_KEY" "$PROJECT_FLATPAK_REPO_BRANCH"
        ___process=$?
        cd "$__current_path" && unset __current_path
        if [ $___process -ne 0 ]; then
                I18N_Conclude_Failed
                return 1
        fi


        # report status
        return 0
}




RELEASE_Setup_FLATPAK() {
        #__repo_directory="$1"


        # validate input
        I18N_Check "FLATPAK"
        if [ $(STRINGS_Is_Empty "$PROJECT_FLATPAK_URL") -eq 0 ]; then
                I18N_Check_Disabled_Skipped
                return 0 # disabled explicitly
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_FLATPAK_REPO") -eq 0 ] &&
                [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -eq 0 ]; then
                return 0 # single file bundles only
        fi


        # execute
        __source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/flatpak-repo"
        FS_Is_Directory "$__source"
        if [ $? -ne 0 ]; then
                return 0 # no repository setup during package job
        fi

        I18N_Setup "FLATPAK"
        FS_Remove_Silently "$1"
        FS_Move "$__source" "$1"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                FS_Remove_Silently "${1}/.git"
        fi


        # report status
        return 0
}
