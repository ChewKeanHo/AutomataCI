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
. "${LIBS_AUTOMATACI}/services/compilers/node.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Run_NPM() {
        #__target="$1"


        # validate input
        NODE_NPM_Is_Valid "$1"
        if [ $? -ne 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_NODE") -eq 0 ]; then
                return 0 # disabled explicitly
        fi

        I18N_Activate_Environment
        NODE_Activate_Local_Environment
        if [ $? -ne 0 ]; then
                I18N_Activate_Failed
                return 1
        fi


        # execute
        I18N_Publish "NPM"
        if [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                I18N_Check_Login "NPM"
                NODE_NPM_Check_Login
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        return 1
                fi

                NODE_NPM_Publish "$1"
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        return 1
                fi
        else
                # always simulate in case of error or mishaps before any point of no return
                I18N_Simulate_Publish "NPM"
        fi


        # report status
        return 0
}
