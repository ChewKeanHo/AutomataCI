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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/installer.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/versioners/git.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/publishers/homebrew.sh"




RELEASE::run_homebrew() {
        #__target="$1"
        #__repo="$2"


        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                OS::print_status error "registration failed.\n"
                return 1
        fi


        HOMEBREW::is_valid_formula "$1"
        if [ $? -ne 0 ]; then
                return 0
        fi


        # execute
        OS::print_status info "registering ${1} into homebrew repo...\n"
        HOMEBREW::publish "$1" "${2}/Formula/${PROJECT_SKU}.rb"
        if [ $? -ne 0 ]; then
                OS::print_status error "registration failed.\n"
                return 1
        fi


        # report status
        return 0
}




RELEASE::run_homebrew_repo_conclude() {
        #__directory="$1"


        # validate input
        OS::print_status info "committing homebrew release repo...\n"
        if [ -z "$1" ] || [ ! -d "$1" ]; then
                OS::print_status error "commit failed.\n"
                return 1
        fi


        # execute
        __current_path="$PWD"
        cd "$1"
        GIT_Autonomous_Commit "${PROJECT_SKU} ${PROJECT_VERSION}"
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                OS::print_status error "commit failed.\n"
                return 1
        fi

        GIT_Pull_To_Latest
        if [ $? -ne 0 ]; then
                cd "$__current_path" && unset __current_path
                OS::print_status error "commit failed.\n"
                return 1
        fi

        GIT_Push "$PROJECT_CHOCOLATEY_REPO_KEY" "$PROJECT_CHOCOLATEY_REPO_BRANCH"
        __exit=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit -ne 0 ]; then
                OS::print_status error "commit failed.\n"
                return 1
        fi


        # report status
        return 0
}




RELEASE::run_homebrew_repo_setup() {
        # clean up base directory
        OS::print_status info "safety checking release directory...\n"
        if [ -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi
        FS::make_directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"


        # execute
        OS::print_status info "setting up homebrew release repo...\n"
        GIT_Clone_Repo \
                "$PROJECT_PATH_ROOT" \
                "$PROJECT_PATH_RELEASE" \
                "$PWD" \
                "$PROJECT_HOMEBREW_REPO" \
                "$PROJECT_SIMULATE_RELEASE_REPO" \
                "$PROJECT_HOMEBREW_DIRECTORY"
        if [ $? -ne 0 ]; then
                OS::print_status error "setup failed.\n"
                return 1
        fi


        # report status
        return 0
}
