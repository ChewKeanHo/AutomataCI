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
. "${LIBS_AUTOMATACI}/services/compilers/deb.sh"
. "${LIBS_AUTOMATACI}/services/publishers/reprepro.sh"




RELEASE_Run_DEB() {
        __target="$1"
        __directory="$2"


        # validate input
        DEB_Is_Valid "$__target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        I18N_Check_Availability "REPREPRO"
        REPREPRO_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 0
        fi


        # execute
        __conf="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/deb"
        __file="${__conf}/conf/distributions"
        FS::is_file "$__file"
        if [ $? -ne 0 ]; then
                I18N_Create "$__file"
                REPREPRO_Create_Conf \
                        "$__conf" \
                        "$PROJECT_REPREPRO_CODENAME" \
                        "$PROJECT_DEBIAN_DISTRIBUTION" \
                        "$PROJECT_REPREPRO_COMPONENT" \
                        "$PROJECT_REPREPRO_ARCH" \
                        "$PROJECT_GPG_ID"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi
        fi

        __dest="${2}/deb"
        I18N_Create "$__dest"
        FS::make_directory "${__dest}"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi

        I18N_Publish "REPREPRO"
        if [ $(STRINGS_Is_Empty "$PROJECT_SIMULATE_RELEASE_REPO") -ne 0 ]; then
                I18N_Simulate_Publish "REPREPRO"
        else
                REPREPRO_Publish \
                        "$__target" \
                        "$__dest" \
                        "$__conf" \
                        "${__conf}/db" \
                        "$PROJECT_REPREPRO_CODENAME"
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        return 1
                fi
        fi


        # report status
        return 0
}
