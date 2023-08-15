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
CheckPythonIsAvailable() {
        if [ ! -z "$(type -t python3)" ]; then
                program="python3"
        elif [ ! -z "$(type -t python)" ]; then
                program="python"
        else
                >&2 printf "[ ERROR ] - Missing python interpreter. Please install one.\n"
                return 1
        fi
        >&2 printf "[ INFO ] Using: $(python3 --version)\n"
        return 0
}
