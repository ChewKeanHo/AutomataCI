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

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/i18n/translations.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/python.sh"




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


__placeholders="\
${PROJECT_SKU}-src_any-any
${PROJECT_SKU}-homebrew_any-any
${PROJECT_SKU}-chocolatey_any-any
${PROJECT_SKU}-pypi_any-any
"




# build output binary file
case "$PROJECT_OS" in
windows)
        __source="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}.exe"
        ;;
*)
        __source="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
        ;;
esac

__source="${PROJECT_SKU}_${PROJECT_OS}-${PROJECT_ARCH}"
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




# placeholding flag files
old_IFS="$IFS"
while IFS="" read -r __line || [ -n "$__line" ]; do
        __file="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__line}"
        I18N_Build "$__file"
        FS_Touch_File "$__file"
        if [ $? -ne 0 ]; then
                I18N_Build_Failed
                return 1
        fi
done <<EOF
$__placeholders
EOF




# compose documentations
I18N_Build "PDOCS"
__output="${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}/python"
FS_Remake_Directory "${__output}/${PROJECT_OS}-${PROJECT_ARCH}"
pdoc --html \
        --output-dir "${__output}/${PROJECT_OS}-${PROJECT_ARCH}" \
        "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/Libs/"
if [ $? -ne 0 ]; then
        I18N_Build_Failed
        return 1
fi




# report status
return 0
