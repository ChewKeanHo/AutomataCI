#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




GITHUB_Setup_Actions() {
        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_RUN") -eq 0 ] &&
                [ $(STRINGS_Is_Empty "$PROJECT_ROBOT_GITHUB_TOKEN") -eq 0 ]; then
                return 0 # not a Github Actions run
        fi


        # execute
        case "$(OS_Get)" in
        darwin)
                # OS Image = darwin-latest
                ;;
        windows)
                # OS Image = windows-latest
                ;;
        *)
                # OS Image = ubuntu-latest


                ## Construct sudo command if unavailable
                OS_Is_Command_Available "sudo"
                if [ $? -ne 0 ]; then
                        alias="su root --preserve-environment --command "
                fi


                ## Other UNIX systems including Linux
                sudo add-apt-repository universe
                if [ $? -ne 0 ]; then
                        return 1
                fi

                sudo apt-get update
                if [ $? -ne 0 ]; then
                        return 1
                fi

                sudo apt-get install -y libfuse2
                if [ $? -ne 0 ]; then
                        return 1
                fi
        esac


        # report status
        return 0
}
