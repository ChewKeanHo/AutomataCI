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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/deb.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/reprepro.sh"




RELEASE::run_deb() {
        __target="$1"
        __directory="$2"
        __datastore="$3"
        __db_directory="$4"

        # validate input
        DEB::is_valid "$__target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        OS::print_status info "checking required reprepro availability...\n"
        REPREPRO::is_available
        if [ $? -ne 0 ]; then
                OS::print_status warning "Reprepro is unavailable. Skipping...\n"
                return 0
        fi

        # execute
        __dest="${__directory}/deb"
        OS::print_status info "creating destination path: ${__dest}\n"
        FS::make_directory "${__dest}"
        if [ $? -ne 0 ]; then
                OS::print_status error "create failed.\n"
                return 1
        fi

        OS::print_status info "publishing with reprepro...\n"
        if [ ! -z "$PROJECT_SIMULATE_RELEASE_REPO" ]; then
                OS::print_status warning "Simulating reprepro release...\n"
        else
                REPREPRO::publish \
                        "$__target" \
                        "$__dest" \
                        "${__datastore}/publishers/reprepro" \
                        "${__db_directory}/reprepro" \
                        "$PROJECT_REPREPRO_CODENAME"
                if [ $? -ne 0 ]; then
                        OS::print_status error "publish failed.\n"
                        return 1
                fi
        fi

        # report status
        return 0
}
