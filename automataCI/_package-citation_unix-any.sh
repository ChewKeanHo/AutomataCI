#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/time.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/citation.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Run_CITATION() {
        __citation_cff="$1"


        # assemble citation
        I18N_Create "$__citation_cff"
        CITATION_Build \
                "$__citation_cff" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/ABSTRACTS.txt" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/CITATIONS.yml" \
                "$PROJECT_CITATION" \
                "$PROJECT_CITATION_TYPE" \
                "$(TIME_Format_Date_ISO8601 "$(TIME_Now)")" \
                "$PROJECT_NAME" \
                "$PROJECT_VERSION" \
                "$PROJECT_LICENSE" \
                "$PROJECT_SOURCE_URL" \
                "$PROJECT_SOURCE_URL" \
                "$PROJECT_STATIC_URL" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_CONTACT_EMAIL"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}
