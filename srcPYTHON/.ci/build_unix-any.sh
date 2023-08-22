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

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/python.sh"




# (1) safety checking control surfaces
PYTHON::is_available
if [ $? -ne 0 ]; then
        return 1
fi


PYTHON::activate_venv
if [ $? -ne 0 ]; then
        return 1
fi




# (2) run build services
compiler="pyinstaller"
OS::print_status info "checking ${compiler} availability...\n"
if [ -z "$(type -t "$compiler")" ]; then
        OS::print_status error "missing ${compiler} command.\n"
        return 1
fi


file="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
OS::print_status info "building output file: ${file}\n"
pyinstaller --noconfirm \
        --onefile \
        --clean \
        --distpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}" \
        --workpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}" \
        --specpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}" \
        --name "$file" \
        --hidden-import=main \
        "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/main.py"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# (3) report successful build status
OS::print_status success "\n\n"
return 0
