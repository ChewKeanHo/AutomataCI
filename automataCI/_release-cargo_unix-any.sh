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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/rust.sh"




RELEASE::run_cargo() {
        _target="$1"


        # validate input
        RUST::crate_is_valid "$_target"
        if [ $? -ne 0 ]; then
                return 0
        fi

        OS::print_status info "activating rust local environment...\n"
        RUST::activate_local_environment
        if [ $? -ne 0 ]; then
                OS::print_status error "activation failed.\n"
                return 1
        fi


        # execute
        OS::print_status info "releasing cargo package...\n"
        if [ ! -z "$PROJECT_SIMULATE_RELEASE_REPO" ]; then
                OS::print_status warning "simulating cargo package push...\n"
        else
                OS::print_status info "logging in cargo credentials...\n"
                RUST::cargo_login
                if [ $? -ne 0 ]; then
                        RUST::cargo_logout
                        OS::print_status error "login failed (CARGO_PASSWORD).\n"
                        return 1
                fi

                RUST::cargo_release_crate "$_target"
                __exit_code=$?
                RUST::cargo_logout
                if [ $__exit_code -ne 0 ]; then
                        OS::print_status error "release failed.\n"
                        return 1
                fi
        fi

        OS::print_status info "remove package artifact...\n"
        FS::remove_silently "$_target"


        # report status
        return 0
}
