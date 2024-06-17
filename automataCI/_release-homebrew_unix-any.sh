#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/publishers/homebrew.sh"
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




# define operating variables
HOMEBREW_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/homebrew"




RELEASE_Conclude_HOMEBREW() {
        #__repo_directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_HOMEBREW_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi


        # execute
        I18N_Conclude "HOMEBREW"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Conclude "HOMEBREW"
                return 0
        fi


        # commit the formula first
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

        GIT_Push "$PROJECT_HOMEBREW_REPO_KEY" "$PROJECT_HOMEBREW_REPO_BRANCH"
        ___process=$?
        cd "$__current_path" && unset __current_path
        if [ $___process -ne 0 ]; then
                I18N_Conclude_Failed
                return 1
        fi


        # clean up in case of other release configurations
        if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                # remove traces - single unified repository will take over later
                FS_Remove "$1"
                if [ $? -ne 0 ]; then
                        I18N_Conclude_Failed
                        return 1
                fi

                return 0
        fi

        case "$(STRINGS_To_Lowercase "$PROJECT_RELEASE_REPO_TYPE")" in
        local)
                # remove traces - formula is never stray from its tap repository.
                ;;
        *)
                return 0
                ;;
        esac

        FS_Remove "$1"
        if [ $? -ne 0 ]; then
                I18N_Conclude_Failed
                return 1
        fi


        # report status
        return 0
}





RELEASE_Run_HOMEBREW() {
        #___target="$1"
        #___repo_directory="$2"


        # validate input
        HOMEBREW_Is_Valid_Formula "$1"
        if [ $? -ne 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_HOMEBREW_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi


        # execute
        I18N_Publish "HOMEBREW"
        if [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                __dest="$(printf -- "%.1s" "$(FS_Get_File "$1")")"
                __dest="${2}/Formula/${__dest}/$(FS_Get_File "$1")"
                FS_Make_Housing_Directory "$__dest"
                FS_Copy_File "$1" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        return 1
                fi
        else
                # always simulate in case of error or mishaps before any point of no return
                I18N_Simulate_Publish "HOMEBREW"
        fi


        # report status
        return 0
}




RELEASE_Setup_HOMEBREW() {
        #__repo_directory="$1"


        # validate input
        I18N_Check "HOMEBREW"
        if [ $(STRINGS_Is_Empty "$PROJECT_HOMEBREW_URL") -eq 0 ]; then
                I18N_Check_Disabled_Skipped
                return 0 # disabled explicitly
        fi


        # execute
        I18N_Setup "HOMEBREW"
        FS_Make_Housing_Directory "$1"
        GIT_Clone_Repo \
                "$PROJECT_PATH_ROOT" \
                "$PROJECT_PATH_RELEASE" \
                "$PWD" \
                "$PROJECT_HOMEBREW_REPO" \
                "$PROJECT_SIMULATE_RUN" \
                "homebrew"
        if [ $? -ne 0 ]; then
                I18N_Setup_Failed
                return 1
        fi

        FS_Make_Directory "$1"


        # report status
        return 0
}
