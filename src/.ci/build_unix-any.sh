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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/time.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/changelog.sh"




# safety checking control surfaces
I18N_Check_Availability 'CHANGELOG'
CHANGELOG_Is_Available
if [ $? -ne 0 ]; then
        I18N_Check_Failed
        return 1
fi




# execute
__directory="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/changelog"
I18N_Create "${PROJECT_VERSION} DATA CHANGELOG"
CHANGELOG_Build_Data_Entry "$__directory"
if [ $? -ne 0 ]; then
        I18N_Create_Failed
        return 1
fi


I18N_Create "${PROJECT_VERSION} DEB CHANGELOG"
CHANGELOG_Build_DEB_Entry \
        "$__directory" \
        "$PROJECT_VERSION" \
        "$PROJECT_SKU" \
        "$PROJECT_DEB_DISTRIBUTION" \
        "$PROJECT_DEB_URGENCY" \
        "$PROJECT_CONTACT_NAME" \
        "$PROJECT_CONTACT_EMAIL" \
        "$(TIME_Format_Datetime_RFC5322 "$(TIME_Now)")"
if [ $? -ne 0 ]; then
        I18N_Create_Failed
        return 1
fi




# report status
return 0
