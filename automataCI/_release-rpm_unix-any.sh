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
. "${LIBS_AUTOMATACI}/services/compilers/rpm.sh"
. "${LIBS_AUTOMATACI}/services/publishers/createrepo.sh"
. "${LIBS_AUTOMATACI}/services/versioners/git.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




# define operating variables
RPM_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}" # default: flat mode
if [ $(STRINGS_Is_Empty "$PROJECT_RPM_FLAT_MODE") -eq 0 ]; then
        ## conventional mode
        RPM_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/rpm"
        case "$(STRINGS_To_Lowercase "$PROJECT_RELEASE_REPO_TYPE")" in
        local)
                # retain existing path
                ;;
        *)
                # fallback to git mode
                if [ $(STRINGS_Is_Empty "$PROJECT_RPM_PATH") -ne 0 ]; then
                        RPM_REPO="${RPM_REPO}/${PROJECT_RPM_PATH}"
                fi
                ;;
        esac

        ## overrides if PROJECT_RELEASE_REPO is set
        if [ $(STRINGS_Is_Empty "$PROJECT_RELEASE_REPO") -ne 0 ]; then
                RPM_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/rpm"
        fi
fi




RELEASE_Conclude_RPM() {
        #__repo_directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_RPM_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi

        CREATEREPO_Is_Available
        if [ $? -ne 0 ]; then
                return 0 # nothing to execute without createrepo or createrepo_c.
        fi


        # execute
        I18N_Conclude "RPM"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Conclude "RPM"
                return 0
        elif [ $(STRINGS_Is_Empty "$PROJECT_RPM_FLAT_MODE") -ne 0 ]; then
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
                "$PROJECT_RPM_REPO_KEY" \
                "$PROJECT_RPM_REPO_BRANCH"
        ___process=$?
        cd "$__current_path" && unset __current_path
        if [ $___process -ne 0 ]; then
                I18N_Conclude_Failed
                return 1
        fi


        # report status
        return 0
}




RELEASE_Run_RPM() {
        #__target="$1"
        #__repo_directory="$2"


        # validate input
        RPM_Is_Valid "$1"
        if [ $? -ne 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_RPM_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi

        CREATEREPO_Is_Available
        if [ $? -ne 0 ]; then
                return 0 # can't execute without createrepo or createrepo_c.
        fi


        # execute
        I18N_Publish "RPM"
        if [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                if [ $(STRINGS_Is_Empty "$PROJECT_RPM_FLAT_MODE") -eq 0 ]; then
                        FS_Copy_File "$1" "${2}/$(FS_Get_File "$1")"
                        if [ $? -ne 0 ]; then
                                I18N_Publish_Failed
                                return 1
                        fi
                fi
        else
                # always simulate in case of error or mishaps before any point of no return
                I18N_Simulate_Publish "RPM"
        fi


        # report status
        return 0
}




RELEASE_Setup_RPM() {
        #__repo_directory="$1"


        # validate input
        I18N_Check "RPM"
        if [ $(STRINGS_Is_Empty "$PROJECT_RPM_URL") -eq 0 ]; then
                I18N_Check_Disabled_Skipped
                return 0 # disabled explicitly
        fi

        I18N_Check_Availability "CREATEREPO"
        CREATEREPO_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed_Skipped
                return 0 # pipeline cannot run without createrepo or createrepo_c
        fi


        # execute
        I18N_Setup "RPM"
        if [ $(STRINGS_Is_Empty "$PROJECT_RPM_FLAT_MODE") -eq 0 ]; then
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
                        "$PROJECT_RPM_REPO" \
                        "$PROJECT_SIMULATE_RUN" \
                        "rpm"
                if [ $? -ne 0 ]; then
                        I18N_Setup_Failed
                        return 1
                fi

                FS_Make_Directory "$1"
        fi


        # report status
        return 0
}




RELEASE_Update_RPM() {
        #__repo_directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_RPM_URL") -eq 0 ]; then
                return 0 # disabled explicitly
        fi

        CREATEREPO_Is_Available
        if [ $? -ne 0 ]; then
                return 0 # can't execute without createrepo or createrepo_c.
        fi


        # execute
        I18N_Publish "RPM"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                I18N_Simulate_Publish "RPM"
                return 0
        fi

        CREATEREPO_Publish "$1"
        if [ $? -ne 0 ]; then
                I18N_Publish_Failed
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_RPM_FLAT_MODE") -ne 0 ]; then
                # flattening requested
                RPM_Flatten_Repo "$1" \
                        "$PROJECT_RPM_REPOXML_NAME" \
                        "$PROJECT_RPM_METALINK" \
                        "$PROJECT_RPM_URL"
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        return 1
                fi
        fi


        # create the README.md
        if [ $(STRINGS_Is_Empty "$PROJECT_RPM_FLAT_MODE") -ne 0 ]; then
                # stop here - report status
                return 0
        fi

        __dest="${1}/RPM_Repository.md"
        I18N_Create "$__dest"
        FS_Make_Housing_Directory "$__dest"
        FS_Remove_Silently "$__dest"
        FS_Write_File "$__dest" "\
# RPM Distribution Repository

This directory is now re-purposed to host RPM packages repository.
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}
