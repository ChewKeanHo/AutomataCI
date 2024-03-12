#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




PYTHON_Activate_VENV() {
        # validate input
        PYTHON_Is_VENV_Activated
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        ___location="$(PYTHON_Get_Activator_Path)"
        FS_Is_File "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        . "$___location"
        PYTHON_Is_VENV_Activated
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # report status
        return 0
}




PYTHON_Check_PYPI_Login() {
        # execute
        if [ $(STRINGS_Is_Empty "$TWINE_USERNAME") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$TWINE_PASSWORD") -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}




PYTHON_Clean_Artifact() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "find"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        find "$1" | grep -E "(__pycache__|\.pyc$)" | xargs rm -rf &> /dev/null


        # report status
        return 0
}




PYTHON_Create_PYPI_Archive() {
        ___directory="$1"
        ___destination="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___destination") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___directory}/pyproject.toml"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___destination"
        if [ $? -ne 0 ]; then
                return 1
        fi

        PYTHON_PYPI_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # construct archive
        ___current_path="$PWD" && cd "$___directory"
        python -m build --sdist --wheel .
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        twine check "${___directory}/dist/"*
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi
        cd "$___current_path" && unset ___current_path


        # export to destination
        for ___file in "${___directory}/dist/"*; do
                FS_Move "$___file" "$___destination"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done


        # report status
        return 0
}




PYTHON_Create_PYPI_Config() {
        ___directory="$1"
        ___project_name="$2"
        ___version="$3"
        ___name="$4"
        ___email="$5"
        ___website="$6"
        ___pitch="$7"
        ___readme_path="$8"
        ___readme_type="$9"
        ___license="${10}"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___project_name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___email") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___pitch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___readme_path") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___readme_type") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___license") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___directory}/${___readme_path}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # check existing overriding file
        FS_Is_File "${___directory}/pyproject.toml"
        if [ $? -eq 0 ]; then
                return 2
        fi


        # create default file
        FS_Write_File "${___directory}/pyproject.toml" "\
[build-system]
requires = [ 'setuptools' ]
build-backend = 'setuptools.build_meta'

[project]
name = '${___project_name}'
version = '${___version}'
description = '${___pitch}'

[project.license]
text = '${___license}'

[project.readme]
file = '${___readme_path}'
'content-type' = '${___readme_type}'

[[project.authors]]
name = '${___name}'
email = '${___email}'

[[project.maintainers]]
name = '${___name}'
email = '${___email}'

[project.urls]
Homepage = '${___website}'
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




PYTHON_Get_Activator_Path() {
        ___location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_PYTHON_ENGINE}/bin/activate"
        printf -- "$___location"


        # report status
        return 0
}




PYTHON_Has_PIP() {
        OS_Is_Command_Available "pip"
        return $?
}




PYTHON_Is_Available() {
        # execute
        OS_Is_Command_Available "python3"
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "python"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




PYTHON_Is_Valid_PYPI() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        STRINGS_Has_Prefix "pypi" "${1##*/}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___hasWHL=false
        ___hasTAR=false
        for ___file in "${1}/"*; do
                if [ ! "${___file%%.whl*}" = "${___file}" ]; then
                        ___hasWHL=true
                elif [ ! "${___file%%.tar*}" = "${___file}" ]; then
                        ___hasTAR=true
                fi
        done

        if [ "$___hasWHL" = "true" ] && [ "$___hasTAR" = "true" ]; then
                return 0
        fi


        # report status
        return 1
}




PYTHON_Is_VENV_Activated() {
        # execute
        if [ $(STRINGS_Is_Empty "$VIRTUAL_ENV") -ne 0 ] ; then
                return 0
        fi


        # report status
        return 1
}




PYTHON_PYPI_Is_Available() {
        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_PYTHON") -eq 0 ]; then
                return 1
        fi


        # execute
        PYTHON_Is_VENV_Activated
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "twine"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




PYTHON_Release_PYPI() {
        ___target="$1"
        ___gpg="$2"
        ___url="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___gpg") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___url") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___target"
        if [ $? -ne 0 ]; then
                return 1
        fi

        PYTHON_PYPI_Is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        twine check "${___target}/"*
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        twine upload "${___target}/"* \
                --sign \
                --identity "$___gpg" \
                --repository-url "$___url" \
                --non-interactive
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




PYTHON_Setup() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "python"
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "python3"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        brew install python
        if [ $? -ne 0 ]; then
                return 1
        fi

        PYTHON_Setup_VENV
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 1
}




PYTHON_Setup_VENV() {
        # validate input
        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_ROOT") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_PATH_TOOLS") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_PATH_PYTHON_ENGINE") -eq 0 ]; then
                return 1
        fi

        PYTHON_Activate_VENV
        if [ $? -eq 0 ]; then
                # already available
                return 0
        fi


        # execute
        ___program=""
        if [ ! -z "$(type -t python3)" ]; then
                ___program="python3"
        elif [ ! -z "$(type -t python)" ]; then
                ___program="python"
        else
                return 1
        fi

        ___location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_PYTHON_ENGINE}"
        $___program -m venv "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        PYTHON_Activate_VENV
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
