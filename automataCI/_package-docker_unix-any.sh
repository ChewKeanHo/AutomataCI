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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/docker.sh"




PACKAGE::run_docker() {
        _dest="$1"
        _target="$2"
        _target_filename="$3"
        _target_os="$4"
        _target_arch="$5"

        OS::print_status info "checking docker functions availability...\n"
        DOCKER::is_available
        case $? in
        2)
                OS::print_status warning "DOCKER is incompatible (OS type). Skipping.\n"
                return 0
                ;;
        3)
                OS::print_status warning "DOCKER is incompatible (CPU type). Skipping.\n"
                return 0
                ;;
        0)
                ;;
        *)
                OS::print_status warning "DOCKER is unavailable. Skipping.\n"
                return 0
                ;;
        esac

        # prepare workspace and required values
        _src="${__target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/docker_${_src}.tar"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/docker_${_src}"
        OS::print_status info "dockering ${_src} for ${_target_os}-${_target_arch}\n"
        OS::print_status info "remaking workspace directory ${_src}\n"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                OS::print_status error "remake failed.\n"
                return 1
        fi

        # copy all complimentary files to the workspace
        OS::print_status info "assembling package files...\n"
        OS::is_command_available "PACKAGE::assemble_docker_content"
        if [ $? -ne 0 ]; then
                OS::print_status error "missing PACKAGE::assemble_docker_content function.\n"
                return 1
        fi

        PACKAGE::assemble_docker_content \
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

        # check required files
        OS::print_status info "checking required dockerfile...\n"
        FS::is_file "${_src}/Dockerfile"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # change location into the workspace
        __current_path="$PWD" && cd "$_src"

        # archive the assembled payload
        OS::print_status info "packaging docker image: ${_target_path}\n"
        DOCKER::create \
                "$_target_path" \
                "$_target_os" \
                "$_target_arch" \
                "$PROJECT_REPO_ID" \
                "$PROJECT_SKU" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi

        # clean up dangling images
        OS::print_status info "cleaning up dangling images...\n"
        DOCKER::clean_up
        if [ $? -ne 0 ]; then
                OS::print_status error "package failed.\n"
                return 1
        fi

        # head back to current directory
        cd "$__current_path" && unset __current_path

        # report status
        return 0
}
