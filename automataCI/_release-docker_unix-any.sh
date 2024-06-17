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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/docker.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




RELEASE_Run_DOCKER() {
        __target="$1"


        # validate input
        DOCKER_Is_Valid "$__target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_CONTAINER_REGISTRY") -eq 0 ]; then
                return 0 # disabled explicitly
        fi

        I18N_Check_Availability "DOCKER"
        DOCKER_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # execute
        I18N_Publish "DOCKER"
        if [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                DOCKER_Release "$__target" "$PROJECT_VERSION"
                if [ $? -ne 0 ]; then
                        I18N_Publish_Failed
                        return 1
                fi

                I18N_Clean "$__target"
                FS_Remove_Silently "$__target"
        else
                # always simulate in case of error or mishaps before any point of no return
                I18N_Simulate_Publish "DOCKER"
        fi


        # report status
        return 0
}
