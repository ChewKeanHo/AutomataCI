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




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/python.sh"




# safety checking control surfaces
OS_Print_Status info "checking python|python3 availability...\n"
PYTHON_Is_Available
if [ $? -ne 0 ]; then
        OS_Print_Status error "missing python|python3 intepreter.\n"
        return 1
fi


OS_Print_Status info "activating python venv...\n"
PYTHON_Activate_VENV
if [ $? -ne 0 ]; then
        OS_Print_Status error "activation failed.\n"
        return 1
fi


OS_Print_Status info "checking pyinstaller availability...\n"
if [ -z "$(type -t "pyinstaller")" ]; then
        OS_Print_Status error "missing pyintaller command.\n"
        return 1
fi


OS_Print_Status info "checking pdoc availability...\n"
if [ -z "$(type -t "pdoc")" ]; then
        OS_Print_Status error "missing pdoc command.\n"
        return 1
fi




# build output binary file
case "$PROJECT_OS" in
windows)
        __file="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}.exe"
        ;;
*)
        __file="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
        ;;
esac

__file="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
OS_Print_Status info "building output file: ${__file}\n"
pyinstaller --noconfirm \
        --onefile \
        --clean \
        --distpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}" \
        --workpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}" \
        --specpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}" \
        --name "$__file" \
        --hidden-import=main \
        "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/main.py"
if [ $? -ne 0 ]; then
        OS_Print_Status error "build failed.\n"
        return 1
fi




# placeholding source code flag
__file="${PROJECT_SKU}-src_${PROJECT_OS}-${PROJECT_ARCH}"
OS_Print_Status info "building output file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        OS_Print_Status error "build failed.\n"
        return 1
fi




# placeholding homebrew code flag
__file="${PROJECT_SKU}-homebrew_any-any"
OS_Print_Status info "building output file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        OS_Print_Status error "build failed.\n"
        return 1
fi




# placeholding chocolatey code flag
__file="${PROJECT_SKU}-chocolatey_any-any"
OS_Print_Status info "building output file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        OS_Print_Status error "build failed.\n"
        return 1
fi




# compose documentations
OS_Print_Status info "printing html documentations...\n"
__output="${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}/python"
FS_Remake_Directory "${__output}/${PROJECT_OS}-${PROJECT_ARCH}"
pdoc --html \
        --output-dir "${__output}/${PROJECT_OS}-${PROJECT_ARCH}" \
        "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/Libs/"
if [ $? -ne 0 ]; then
        OS_Print_Status error "compose failed.\n"
        return 1
fi




# report status
return 0
