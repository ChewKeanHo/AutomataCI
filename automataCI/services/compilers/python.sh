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
PYTHON::is_available() {
        if [ ! -z "$(type -t python3)" ]; then
                return 0
        elif [ ! -z "$(type -t python)" ]; then
                return 0
        fi
        return 1
}

PYTHON::is_venv_activated() {
        if [ ! -z "$VIRTUAL_ENV" ] ; then
                return 0
        fi
        return 1
}

PYTHON::has_pip() {
        if [ -z "$(type -t pip)" ]; then
                return 1
        fi
        return 0
}

PYTHON::activate_venv() {
        if [ ! -z "$VIRTUAL_ENV" ] ; then
                return 0
        fi

        location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_PYTHON_ENGINE}"
        location="${location}/bin/activate"
        if [ ! -f "$location" ]; then
                return 1
        fi

        . "$location"
        if [ ! -z "$VIRTUAL_ENV" ] ; then
                return 0
        fi

        return 1
}
