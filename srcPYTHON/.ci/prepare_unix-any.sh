#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




# (0) initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please source from ci.cmd instead!\n"
        return 1
fi




# (1) safety checking control surfaces
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/python/common.sh"
CheckPythonIsAvailable
if [ $? -ne 0 ]; then
        return 1
fi


ActivateVirtualEnvironment
if [ $? -ne 0 ]; then
        return 1
fi


CheckPythonPIP
if [ $? -ne 0 ]; then
        return 1
fi




# (2) run prepare services
pip install -r "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/requirements.txt"
if [ $? -ne 0 ]; then
        return 1
fi
return 0
