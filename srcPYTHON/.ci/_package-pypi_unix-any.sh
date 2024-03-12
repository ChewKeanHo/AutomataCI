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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/python.sh"




PACKAGE_Assemble_PYPI_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS_Is_Target_A_Pypi "$_target") -ne 0 ]; then
                return 10
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PYTHON") -eq 0 ]; then
                return 10
        fi


        # assemble the python package
        ___source="${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/Libs/"
        ___dest="$_directory"
        I18N_Assemble "$___source" "$___dest"
        PYTHON_Clean_Artifact "$___source"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_PYPI_README}"
        ___dest="${_directory}/${PROJECT_PYPI_README}"
        I18N_Assemble "$___source" "$___dest"
        PYTHON_Clean_Artifact "$___source"
        FS_Copy_File "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # generate the pyproject.toml
        ___dest="${_directory}/pyproject.toml"
        I18N_Create "$___dest"
        FS_Write_File "$___dest" "\
[build-system]
requires = [ 'setuptools' ]
build-backend = 'setuptools.build_meta'

[project]
name = '${PROJECT_NAME}'
version = '${PROJECT_VERSION}'
description = '${PROJECT_PITCH}'

[project.license]
text = '${PROJECT_LICENSE}'

[project.readme]
file = '${PROJECT_PYPI_README}'
'content-type' = '${PROJECT_PYPI_README_MIME}'

[[project.authors]]
name = '${PROJECT_CONTACT_NAME}'
email = '${PROJECT_CONTACT_EMAIL}'

[[project.maintainers]]
name = '${PROJECT_CONTACT_NAME}'
email = '${PROJECT_CONTACT_EMAIL}'

[project.urls]
Homepage = '${PROJECT_CONTACT_WEBSITE}'
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}
