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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/angular.sh"




# execute
I18N_Activate_Environment
ANGULAR_Is_Available
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


I18N_Import_Dependencies
__current_path="$PWD" && cd "${PROJECT_PATH_ROOT}/${PROJECT_ANGULAR}"
npm install
___process=$?
cd "$__current_path" && unset __current_path
if [ $___process -ne 0 ]; then
        I18N_Import_Failed
        return 1
fi




# report status
return 0
