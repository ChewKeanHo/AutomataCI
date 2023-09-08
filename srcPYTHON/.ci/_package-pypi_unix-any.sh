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
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




PACKAGE::assemble_pypi_content() {
        __target="$1"
        __directory="$2"
        __target_name="$3"
        __target_os="$4"
        __target_arch="$5"

        # validate project
        FS::is_target_a_source "$__target"
        if [ $? -ne 0 ]; then
                return 10
        fi

        if [ -z "$PROJECT_PYTHON" ]; then
                return 10
        fi

        # assemble the python package
        PYTHON::clean_artifact "${PROJECT_PATH_ROOT}/srcPYTHON/"
        FS::copy_all "${PROJECT_PATH_ROOT}/srcPYTHON/Libs/" "${__directory}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # generate the setup.py
        FS::write_file "${__directory}/setup.py" "\
from setuptools import setup, find_packages

setup(
    name='${PROJECT_NAME}',
    version='${PROJECT_VERSION}',
    author='${PROJECT_CONTACT_NAME}',
    author_email='${PROJECT_CONTACT_EMAIL}',
    url='${PROJECT_CONTACT_WEBSITE}',
    description='${PROJECT_PITCH}',
    packages=find_packages(),
    long_description=open('${PROJECT_PATH_ROOT}/README.md').read(),
    long_description_content_type='text/markdown',
)
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}
