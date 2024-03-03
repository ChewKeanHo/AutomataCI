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




PACKAGE_Assemble_PYPI_content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        FS_Is_Target_A_Source "$_target"
        if [ $? -ne 0 ]; then
                return 10
        fi

        if [ -z "$PROJECT_PYTHON" ]; then
                return 10
        fi


        # assemble the python package
        PYTHON_Clean_Artifact "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/"
        FS_Copy_All "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/Libs/" "${_directory}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_File \
                "${PROJECT_PATH_ROOT}/${PROJECT_PYPI_README}" \
                "${_directory}/${PROJECT_PYPI_README}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # generate the pyproject.toml
        FS_Write_File "${_directory}/pyproject.toml" "\
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
                return 1
        fi


        # report status
        return 0
}
