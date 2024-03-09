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
. "${LIBS_AUTOMATACI}/services/compilers/changelog.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Run_CHANGELOG() {
        __changelog_md="$1"
        __changelog_deb="$2"


        I18N_Check_Availability "CHANGELOG"
        CHANGELOG_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # validate input
        I18N_Validate "${PROJECT_VERSION} CHANGELOG"
        CHANGELOG_Compatible_DATA_Version \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/changelog" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                I18N_Validate_Failed
                return 1
        fi

        I18N_Validate "${PROJECT_VERSION} DEB CHANGELOG"
        CHANGELOG_Compatible_DEB_Version \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/changelog" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                I18N_Validate_Failed
                return 1
        fi


        # assemble changelog
        I18N_Create "$__changelog_md"
        CHANGELOG_Assemble_MD \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/changelog" \
                "$__changelog_md" \
                "$PROJECT_VERSION" \
                "$PROJECT_CHANGELOG_TITLE"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi

        I18N_Create "$__changelog_deb"
        FS_Make_Directory "${__changelog_deb%/*}"
        CHANGELOG_Assemble_DEB \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/changelog" \
                "$__changelog_deb" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}
