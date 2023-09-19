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




RELEASE::run_post_processors() {
        OS::is_command_available "RELEASE::run_post_processor"
        if [ $? -eq 0 ]; then
                OS::print_status info "running post-processing function...\n"
                RELEASE::run_post_processor "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
                case $? in
                10|0)
                        ;;
                *)
                        OS::print_status error "post-processor failed.\n"
                        return 1
                        ;;
                esac
        fi

        # report status
        return 0
}




RELEASE::run_pre_processors() {
        OS::is_command_available "RELEASE::run_pre_processor"
        if [ $? -eq 0 ]; then
                OS::print_status info "running pre-processing function...\n"
                RELEASE::run_pre_processor "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"
                case $? in
                10)
                        OS::print_status warning "release is not required. Skipping process.\n"
                        return 0
                        ;;
                0)
                        ;;
                *)
                        OS::print_status error "pre-processor failed.\n"
                        return 1
                        ;;
                esac
        fi

        # report status
        return 0
}
