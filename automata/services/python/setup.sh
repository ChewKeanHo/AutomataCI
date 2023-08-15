#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
SetupPython() {
        if [ -z "$PROJECT_PATH_ROOT" ]; then
                >&2 printf "[ ERROR ] - Please source from ci.cmd instead!\n"
                return 1
        fi

        if [ -z "$PROJECT_PATH_TOOLS" ]; then
                >&2 printf "[ ERROR ] - Please source from ci.cmd instead!\n"
                return 1
        fi

        if [ -z "$PROJECT_PATH_PYTHON_ENGINE" ]; then
                >&2 printf "[ ERROR ] - Please source from ci.cmd instead!\n"
                return 1
        fi

        location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_PYTHON_ENGINE}"
        mkdir -p "$location"
        if [ ! -f "$location/bin/activate" ]; then
                "$program" -m venv "$location"
                if [ ! -f "$location/bin/activate" ]; then
                        >&2 printf "[ ERROR ] failed to setup virual environment at ${location}\n"
                        unset program location
                        return 1
                fi

                >&2 printf "[ INFO ] ${location} is now established.\n"
        else
                >&2 printf "[ INFO ] ${location} is already established.\n"
        fi
        unset program location
}
