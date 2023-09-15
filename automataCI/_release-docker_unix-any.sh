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




RELEASE::run_docker() {
        _target="$1"
        _directory="$2"
        _datastore="$3"

        # validate input
        DOCKER::is_valid "$_target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        OS::print_status info "checking required docker availability...\n"
        DOCKER::is_available
        if [ $? -ne 0 ]; then
                OS::print_status warning "Docker is unavailable. Skipping...\n"
                return 0
        fi

        # execute
        OS::print_status info "releasing docker as the latest version...\n"
        DOCKER::release "$_target" "$_directory" "$_datastore" "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                OS::print_status error "release failed.\n"
                return 1
        fi

        OS::print_status info "remove package artifact...\n"
        FS::remove_silently "$_target"

        # report status
        return 0
}
