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
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rpm.sh"
. "${LIBS_AUTOMATACI}/services/publishers/createrepo.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Run_RPM() {
        __target="$1"
        __directory="$2"


        # validate input
        RPM_Is_Valid "$__target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        I18N_Check_Availability "CREATEREPO"
        CREATEREPO_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed_Skipped
                return 0
        fi


        # execute
        __dest="${__directory}/rpm"
        I18N_Create "$__dest"
        FS_Make_Directory "${__dest}"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi

        I18N_Publish "CREATEREPO"
        CREATEREPO_Publish "$__target" "${__dest}"
        if [ $? -ne 0 ]; then
                I18N_Publish_Failed
                return 1
        fi


        # report status
        return 0
}
