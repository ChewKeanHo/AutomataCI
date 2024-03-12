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

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/python.sh"




# execute
I18N_Activate_Environment
PYTHON_Activate_VENV
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


__report_location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}/python-test-report"


I18N_Prepare "$__report_location"
FS_Remake_Directory "$__report_location"
if [ $? -ne 0 ]; then
        I18N_Prepare_Failed
        return 1
fi


I18N_Run_Test_Coverage
python -m coverage run \
        --data-file="${__report_location}/.coverage" \
        -m unittest discover \
        -s "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}" \
        -p '*_test.py'
if [ $? -ne 0 ]; then
        I18N_Run_Failed
        return 1
fi


I18N_Processing_Test_Coverage
python -m coverage html \
        --data-file="${__report_location}/.coverage" \
        --directory="$__report_location"
if [ $? -ne 0 ]; then
        I18N_Processing_Failed
        return 1
fi




# return status
return 0
