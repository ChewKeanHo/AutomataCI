#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Run_RESEARCH() {
        #__target="$1"


        # validate input
        if [ $(FS_Is_Target_A_PDF "$1") -ne 0 ]; then
                return 0
        fi

        if [ "${1##*${PROJECT_RESEARCH_IDENTIFIER}}" = "$1" ]; then
                return 0 # not a research paper
        fi


        # execute
        I18N_Publish "RESEARCH"
        if [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                __dest="PAPER.pdf"
                __dest="${PROJECT_PATH_ROOT}/${__dest}"
                I18N_Publish "$__dest"
                FS_Copy_File "$1" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        return 1
                fi
        else
                # always simulate in case of error or mishaps before any point of no return
                I18N_Simulate_Publish "RESEARCH"
        fi


        # report status
        return 0
}
