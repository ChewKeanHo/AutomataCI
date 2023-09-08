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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




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
        OS::is_command_available "pip"
        return $?
}




PYTHON::activate_venv() {
        # validate input
        PYTHON::is_venv_activated
        if [ $? -eq 0 ] ; then
                return 0
        fi

        # execute
        __location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_PYTHON_ENGINE}"
        __location="${__location}/bin/activate"
        if [ ! -f "$__location" ]; then
                return 1
        fi

        . "$__location"

        # report status
        PYTHON::is_venv_activated
        if [ $? -eq 0 ] ; then
                return 0
        fi
        return 1
}




PYTHON::setup_venv() {
        # validate input
        if [ -z "$PROJECT_PATH_ROOT" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_TOOLS" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_PYTHON_ENGINE" ]; then
                return 1
        fi

        # execute
        __program=""
        if [ ! -z "$(type -t python3)" ]; then
                __program="python3"
        elif [ ! -z "$(type -t python)" ]; then
                __program="python"
        else
                return 1
        fi


        # check if the repo is already established...
        __location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_PYTHON_ENGINE}"
        if [ -f "${__location}/bin/activate" ]; then
                return 0
        fi

        # it's a clean repo. Start setting up virtual environment...
        $__program -m venv "$__location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        if [ -f "${__location}/bin/activate" ]; then
                return 0
        fi
        return 1
}




PYTHON::clean_artifact() {
        # __target="$1"

        # validate input
        if [ -z "$1" ] || [ ! -d "$1" ]; then
                return 1
        fi

        OS::is_command_available "find"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        find "$1" | grep -E "(__pycache__|\.pyc$)" | xargs rm -rf &> /dev/null

        # report status
        return 0
}




PYPI::is_available() {
        # validate input
        if [ -z "$PROJECT_PYTHON" ]; then
                return 1
        fi

        # execute
        PYTHON::is_venv_activated
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "twine"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




PYPI::create_setup_py() {
        __directory="$1"
        __project_name="$2"
        __version="$3"
        __name="$4"
        __email="$5"
        __website="$6"
        __pitch="$7"
        __readme_path="$8"
        __readme_type="$9"

        # validate input
        if [ -z "$__directory" ] ||
                [ -z "$__project_name" ] ||
                [ -z "$__version" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__website" ] ||
                [ -z "$__pitch" ] ||
                [ -z "$__readme_path" ] ||
                [ -z "$__readme_type" ] ||
                [ ! -d "$__directory" ]; then
                return 1
        fi

        # check existing overriding file
        if [ -f "${__directory}/setup.py" ]; then
                return 2
        fi

        # create default file
        FS::write_file "${__directory}/setup.py" "\
from setuptools import setup, find_packages


setup(
    name='${__project_name}',
    version='${__version}',
    author='${__name}',
    author_email='${__email}',
    url='${__website}',
    description='${__pitch}',
    packages=find_packages(),
    long_description=open('${__readme_path}').read(),
    long_description_content_type='${__readme_type}',
)
"

        # report status
        return $?
}




PYPI::create_archive() {
        __directory="$1"
        __destination="$2"

        # validate input
        if [ -z "$__directory" ] ||
                [ -z "$__destination" ] ||
                [ ! -d "$__directory" ] ||
                [ ! -f "${__directory}/setup.py" ] ||
                [ ! -d "$__destination" ]; then
                return 1
        fi

        PYPI::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # construct archive
        __current_path="$PWD" && cd "$__directory"
        python "${__directory}/setup.py" sdist bdist_wheel
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi

        twine check "${__directory}/dist/"*
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                return 1
        fi
        cd "$__current_path" && unset __current_path

        # export to destination
        for __file in "${__directory}/dist/"*; do
                FS::move "$__file" "$__destination"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done

        # report status
        return 0
}
