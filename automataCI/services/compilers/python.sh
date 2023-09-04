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
        if [ -z "$(type -t pip)" ]; then
                return 1
        fi
        return 0
}




PYTHON::activate_venv() {
        PYTHON::is_venv_activated
        if [ $? -eq 0 ] ; then
                return 0
        fi

        __location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_PYTHON_ENGINE}"
        __location="${__location}/bin/activate"
        if [ ! -f "$__location" ]; then
                unset __location
                return 1
        fi

        . "$__location"
        unset __location

        PYTHON::is_venv_activated
        if [ $? -eq 0 ] ; then
                return 0
        fi
        return 1
}




PYTHON::setup_venv() {
        if [ -z "$PROJECT_PATH_ROOT" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_TOOLS" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_PYTHON_ENGINE" ]; then
                return 1
        fi

        __program=""
        if [ ! -z "$(type -t python3)" ]; then
                __program="python3"
        elif [ ! -z "$(type -t python)" ]; then
                __program="python"
        else
                return 1
        fi

        __location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_PYTHON_ENGINE}"
        mkdir -p "$__location"


        # check if the repo is already established...
        if [ -f "${__location}/bin/activate" ]; then
                unset __location __program
                return 0
        fi


        # it's a clean repo. Start setting up virtual environment...
        $__program -m venv "$__location"
        if [ $? -ne 0 ]; then
                unset __location __program
                return 1
        fi


        # last check
        if [ -f "${__location}/bin/activate" ]; then
                unset __location __program
                return 0
        fi

        unset __location __program
        return 1
}




PYTHON::clean_artifact() {
        find "${PROJECT_PATH_ROOT}/srcPYTHON/" \
                | grep -E "(__pycache__|\.pyc$)" \
                | xargs rm -rf \
                &> /dev/null
        return 0
}




PYPI::is_available() {
        if [ -z "$PROJECT_PYTHON" ]; then
                return 1
        fi

        PYTHON::is_venv_activated
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ -z "$(type -t twine)" ]; then
                return 1
        fi

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
                unset __directory \
                        __project_name \
                        __version \
                        __name \
                        __email \
                        __website \
                        __pitch \
                        __readme_path \
                        __readme_type
                return 1
        fi

        # check existing overriding file
        if [ -f "${__directory}/setup.py" ]; then
                return 2
        fi

        # create default file
        printf "\
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
" > "${__directory}/setup.py"

        # report status
        unset __directory \
                __project_name \
                __version \
                __name \
                __email \
                __website \
                __pitch \
                __readme_path \
                __readme_type
        return 0
}




PYPI::create_archive() {
        __directory="$1"
        __destination="$2"

        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ ! -f "${__directory}/setup.py" ] ||
                [ ! -d "$__destination" ]; then
                unset __directory __destination
                return 1
        fi

        PYPI::is_available
        if [ $? -ne 0 ]; then
                unset __directory __destination
                return 1
        fi

        # construct archive
        __current_path="$PWD" && cd "$__directory"
        python "${__directory}/setup.py" sdist bdist_wheel
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                unset __directory __destination
                return 1
        fi

        twine check "${__directory}/dist/"*
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                unset __directory __destination
                return 1
        fi
        cd "$__current_path" && unset __current_path

        # export to destination
        mv "${__directory}/dist/"* "${__destination}/."
        __exit=$?

        # report status
        unset __directory __destination
        return $__exit
}
