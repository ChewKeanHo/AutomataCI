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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/node.sh"




# execute
I18N_Activate_Environment
NODE_Activate_Local_Environment
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


I18N_Run_Test_Coverage
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_NODE}"
if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
        I18N_Simulate_Testing
        return 0
else
        NODE_NPM_Run "test"
        if [ $? -ne 0 ]; then
                I18N_Run_Failed
                return 1
        fi
fi
cd "$__current_path" && unset __current_path


I18N_Processing_Test_Coverage
___source="${PROJECT_PATH_ROOT}/${PROJECT_NODE}/dist/coverage"
___dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/node-test-report"
FS_Is_Directory "$___source"
if [ $? -ne 0 ]; then
        I18N_Processing_Failed
        return 1
fi

FS_Remove_Silently "$___dest"
FS_Make_Housing_Directory "$___dest"
FS_Move "$___source" "$___dest"
if [ $? -ne 0 ]; then
        I18N_Processing_Failed
        return 1
fi




# return status
return 0
