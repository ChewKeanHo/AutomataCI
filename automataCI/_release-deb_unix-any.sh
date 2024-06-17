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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/deb.sh"
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




# define operating variables
DEB_REPO_DATA="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/releaser-deb-repoDB"
if [ $(STRINGS_Is_Empty "$PROJECT_DEB_PATH_DATA") -ne 0 ]; then
        DEB_REPO_DATA="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/data/deb/${PROJECT_DEB_PATH_DATA}"
fi

DEB_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}" # default: flat mode
if [ "${PROJECT_DEB_DISTRIBUTION%%/*}" = "$PROJECT_DEB_DISTRIBUTION" ]; then
        ## conventional mode
        DEB_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/deb"
        case "$(STRINGS_To_Lowercase "$PROJECT_RELEASE_REPO_TYPE")" in
        local)
                ;;
        *)
                # fallback to git mode
                if [ $(STRINGS_Is_Empty "$PROJECT_DEB_PATH") -ne 0 ]; then
                        DEB_REPO="${DEB_REPO}/${PROJECT_DEB_PATH}"
                fi
                ;;
        esac

        ## overrides if PROJECT_RELEASE_REPO is set
        if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                DEB_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/deb"
        fi
fi




RELEASE_Conclude_DEB() {
        #__repo_directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_DEB_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi


        # execute
        I18N_Conclude "DEB"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Conclude "DEB"
                return 0
        elif [ ! "${PROJECT_DEB_DISTRIBUTION%%/*}" = "$PROJECT_DEB_DISTRIBUTION" ]; then
                # nothing to do in flat mode - report status
                return 0
        elif [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                # do nothing - single unified repository will take over later
                return 0
        fi

        case "$(STRINGS_To_Lowercase "$PROJECT_RELEASE_REPO_TYPE")" in
        local)
                # nothing to do for local directory type - report status
                return 0
                ;;
        *)
                # repository is an independent git repository so proceed as follows.
                ;;
        esac


        # commit release
        __current_path="$PWD" && cd "$1"
        GIT_Autonomous_Force_Commit \
                "$PROJECT_VERSION" \
                "$PROJECT_DEB_REPO_KEY" \
                "$PROJECT_DEB_REPO_BRANCH"
        ___process=$?
        cd "$__current_path" && unset __current_path
        if [ $___process -ne 0 ]; then
                I18N_Conclude_Failed
                return 1
        fi


        # report status
        return 0
}




RELEASE_Run_DEB() {
        __target="$1"
        __repo_directory="$2"
        __data_directory="$3"


        # validate input
        DEB_Is_Valid "$__target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_DEB_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi


        # execute
        I18N_Publish "DEB"
        if [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                DEB_Publish \
                        "$__repo_directory" \
                        "$__data_directory" \
                        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/releaser-deb" \
                        "$__target" \
                        "$PROJECT_DEB_DISTRIBUTION" \
                        "$PROJECT_DEB_COMPONENT"
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        return 1
                fi
        else
                # always simulate in case of error or mishaps before any point of no return
                I18N_Simulate_Publish "DEB"
        fi


        # report status
        return 0
}




RELEASE_Setup_DEB() {
        #__repo_directory="$1"


        # validate input
        I18N_Check "DEB"
        if [ $(STRINGS_Is_Empty "$PROJECT_DEB_URL") -eq 0 ]; then
                I18N_Check_Disabled_Skipped
                return 0 # disabled explicitly
        fi


        # execute
        I18N_Setup "DEB"
        if [ "${PROJECT_DEB_DISTRIBUTION%%/*}" = "$PROJECT_DEB_DISTRIBUTION" ]; then
                # conventional mode
                if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                        ## overridden by single unified repository
                        FS_Remake_Directory "$1"
                        return 0
                fi

                case "$(STRINGS_To_Lowercase "$PROJECT_RELEASE_REPO_TYPE")" in
                local)
                        ## local file directory type
                        FS_Remake_Directory "$1"
                        return 0
                        ;;
                *)
                        ## fallback to git repository source
                        ;;
                esac

                FS_Make_Housing_Directory "$1"
                GIT_Clone_Repo \
                        "$PROJECT_PATH_ROOT" \
                        "$PROJECT_PATH_RELEASE" \
                        "$PWD" \
                        "$PROJECT_DEB_REPO" \
                        "$PROJECT_SIMULATE_RUN" \
                        "deb"
                if [ $? -ne 0 ]; then
                        I18N_Setup_Failed
                        return 1
                fi

                FS_Make_Directory "$1"
        fi


        # report status
        return 0
}




RELEASE_Update_DEB() {
        #__repo_directory="$1"
        #__data_directory="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_DEB_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi


        # execute
        I18N_Publish "DEB"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Publish "DEB"
                return 0
        fi

        DEB_Publish_Conclude \
                "$1" \
                "$2" \
                "$PROJECT_DEB_DISTRIBUTION" \
                "$PROJECT_DEB_ARCH" \
                "$PROJECT_DEB_COMPONENT" \
                "$PROJECT_DEB_CODENAME" \
                "$PROJECT_GPG_ID"
        if [ $? -ne 0 ]; then
                I18N_Publish_Failed
                return 1
        fi


        # create the README.md
        if [ ! "${PROJECT_DEB_DISTRIBUTION%%/*}" = "$PROJECT_DEB_DISTRIBUTION" ]; then
                # it's flat repo so stop here - no README.md is required
                return 0
        fi

        __dest="${1}/DEB_Repository.md"
        I18N_Create "$__dest"
        FS_Make_Housing_Directory "$__dest"
        FS_Remove_Silently "$__dest"
        FS_Write_File "$__dest" "\
# DEB Distribution Repository

This directory is now re-purposed to host DEB packages repository.
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}
