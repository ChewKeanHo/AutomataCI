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
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/changelog.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Conclude_CHANGELOG() {
        # execute
        I18N_Export "${PROJECT_VERSION} CHANGELOG"
        CHANGELOG_Seal \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/changelog" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                I18N_Export_Failed
                return 1
        fi


        # report status
        return 0
}
