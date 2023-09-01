#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
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




# (1) construct json array
__output=""


if [ ! -z "$PROJECT_PYTHON" ]; then
        if [ ! -z "$__output" ]; then
                __output="${__output} "
        fi
        __output="${__output}python"
fi





# (2) print output
__output="value='${__output}'"

if [ ! -z "$GITHUB_OUTPUT" ]; then
        printf -- "${__output}" >> "$GITHUB_OUTPUT"
fi

>&2 printf -- "${__output}\n"
return 0
