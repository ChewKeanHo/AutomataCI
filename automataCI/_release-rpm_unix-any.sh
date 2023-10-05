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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rpm.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/createrepo.sh"




RELEASE::run_rpm() {
        __target="$1"
        __directory="$2"


        # validate input
        RPM::is_valid "$__target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        OS::print_status info "checking required createrepo availability...\n"
        CREATEREPO::is_available
        if [ $? -ne 0 ]; then
                OS::print_status warning "Createrepo is unavailable. Skipping...\n"
                return 0
        fi


        # execute
        __dest="${2}/rpm"
        OS::print_status info "creating destination path: ${__dest}\n"
        FS::make_directory "${__dest}"
        if [ $? -ne 0 ]; then
                OS::print_status error "create failed.\n"
                return 1
        fi

        OS::print_status info "publishing with createrepo...\n"
        CREATEREPO::publish "$__target" "${__dest}"
        if [ $? -ne 0 ]; then
                OS::print_status error "publish failed.\n"
                return 1
        fi


        # report status
        return 0
}
