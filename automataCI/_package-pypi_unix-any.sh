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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/python.sh"




PACKAGE::run_pypi() {
        _dest="$1"
        _target="$2"
        _target_filename="$3"
        _target_os="$4"
        _target_arch="$5"

        if [ ! -z "$PROJECT_PYTHON" ]; then
                PYTHON::activate_venv
        fi

        PYPI::is_available
        if [ $? -ne 0 ]; then
                OS::print_status warning "PyPi is incompatible or not available. Skipping.\n"
                return 0
        fi

        # prepare workspace and required values
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/pypi_${_src}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/pypi_${_src}"
        OS::print_status info "Creating PyPi source code package...\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi

        OS::print_status info "checking output file existence...\n"
        if [ -d "$_target_path" ]; then
                OS::print_status error "check failed - output exists!\n"
                return 1
        fi

        # copy all complimentary files to the workspace
        OS::print_status info "assembling package files...\n"
        if [ -z "$(type -t PACKAGE::assemble_pypi_content)" ]; then
                OS::print_status error "missing PACKAGE::assemble_pypi_content function.\n"
                return 1
        fi
        PACKAGE::assemble_pypi_content \
                "$_target" \
                "$_src" \
                "$_target_filename" \
                "$_target_os" \
                "$_target_arch"
        case $? in
        10)
                FS::remove_silently "$_src"
                OS::print_status warning "packaging is not required. Skipping process.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status error "assembly failed.\n"
                return 1
                ;;
        esac

        # generate required files
        OS::print_status info "creating setup.py file...\n"
        PYPI::create_setup_py \
                "$_src" \
                "$PROJECT_NAME" \
                "$PROJECT_VERSION" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_PITCH" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PYPI_README}" \
                "$PROJECT_PYPI_README_MIME"
        case $? in
        2)
                OS::print_status info "manual injection detected.\n"
                ;;
        0)
                ;;
        *)
                OS::print_status error "create failed.\n"
                return 1
                ;;
        esac

        # archive the assembled payload
        OS::print_status info "archiving PyPi package...\n"
        FS::make_directory "$_target_path"
        PYPI::create_archive "$_src" "$_target_path"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi

        # report status
        return 0
}
