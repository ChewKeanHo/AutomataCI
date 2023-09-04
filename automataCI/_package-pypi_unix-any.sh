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
        __target="$1"
        __target_filename="$2"
        __target_sku="$3"
        __target_os="$4"
        __target_arch="$5"

        if [ ! -z "$PROJECT_PYTHON" ]; then
                PYTHON::activate_venv
        fi

        PYPI::is_available
        if [ $? -ne 0 ]; then
                OS::print_status warning "PyPi is incompatible or not available. Skipping.\n"
                return 0
        fi

        FS::is_target_a_source "$__target"
        if [ $? -eq 0 ]; then
                __src="pypi-src_${__target_filename}_${__target_os}-${__target_arch}"
        else
                __src="pypi_${__target_filename}_${__target_os}-${__target_arch}"
        fi
        __src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${__src}"
        __dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
        OS::print_status info "Creating PyPi source code package...\n"
        OS::print_status info "remaking workspace directory $__src\n"
        FS::remake_directory "$__src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi
        __target="$1"

        __target_path="${__dest}/pypi_${__target_sku}_${__target_os}-${__target_arch}"
        OS::print_status info "checking output file existence...\n"
        if [ -d "$__target_path" ]; then
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
                "$__target" \
                "$__src" \
                "$__target_filename" \
                "$__target_os" \
                "$__target_arch"
        __exit=$?
        if [ $__exit -eq 10 ]; then
                FS::remove_silently "$__src"
                OS::print_status warning "packaging is not required. Skipping process.\n"
                return 0
        elif [ $__exit -ne 0 ]; then
                OS::print_status error "assembly failed.\n"
                return 1
        fi

        # generate required files
        OS::print_status info "creating setup.py file...\n"
        PYPI::create_setup_py \
                "$__src" \
                "$PROJECT_NAME" \
                "$PROJECT_VERSION" \
                "$PROJECT_CONTACT_NAME" \
                "$PROJECT_CONTACT_EMAIL" \
                "$PROJECT_CONTACT_WEBSITE" \
                "$PROJECT_PITCH" \
                "${PROJECT_PATH_ROOT}/README.md" \
                "text/markdown"
        __exit=$?
        if [ $__exit -eq 2 ]; then
                OS::print_status info "manual injection detected.\n"
        elif [ $__exit -ne 0 ]; then
                OS::print_status error "create failed.\n"
                return 1
        fi

        # archive the assembled payload
        OS::print_status info "archiving .pypi package...\n"
        mkdir -p "$__target_path"
        PYPI::create_archive "$__src" "$__target_path"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi

        # report status
        return 0
}
