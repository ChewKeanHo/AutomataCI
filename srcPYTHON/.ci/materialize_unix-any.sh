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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/python.sh"




# execute
I18N_Activate_Environment
PYTHON_Activate_VENV
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


I18N_Check "PYINSTALLER"
OS_Is_Command_Available "pyinstaller"
if [ $? -ne 0 ]; then
        I18N_Check_Failed
        return 1
fi


I18N_Check "PDOC"
OS_Is_Command_Available "pdoc"
if [ $? -ne 0 ]; then
        I18N_Check_Failed
        return 1
fi




# build output binary file
case "$PROJECT_OS" in
windows)
        __source="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}.exe"
        ;;
*)
        __source="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
        ;;
esac

I18N_Build "$__source"
pyinstaller --noconfirm \
        --onefile \
        --clean \
        --distpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}" \
        --workpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}" \
        --specpath "${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}" \
        --name "$__source" \
        --hidden-import=main \
        "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/main.py"
if [ $? -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi




# shipping executable
__source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__source}"
__dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BIN}/${PROJECT_SKU}"
I18N_Export "$__source" "$__dest"
FS_Make_Housing_Directory "$__dest"
FS_Remove_Silently "$__dest"
FS_Move "$__source" "$__dest"
if [ $? -ne 0 ]; then
        I18N_Export_Failed
        return 1
fi




# report status
return 0
