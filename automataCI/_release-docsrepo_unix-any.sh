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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/versioners/git.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/installer.sh"




RELEASE::docs_repo() {
        # validate input
        OS::print_status info "publishing artifacts to docs repo...\n"
        if [ ! -d "${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}" ]; then
                OS::print_status warning "release skipped - No docs directory.\n"
                return 0
        fi


        # clean up base directory
        OS::print_status info "safety checking docs repo directory...\n"
        if [ -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_DOCS_REPO_DIRECTORY}" ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi
        FS::make_directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"


        # execute
        OS::print_status info "setting up release docs repo...\n"
        INSTALLER::setup_resettable_repo \
                "$PROJECT_PATH_ROOT" \
                "$PROJECT_PATH_RELEASE" \
                "$PWD" \
                "$PROJECT_DOCS_REPO" \
                "$PROJECT_SIMULATE_RELEASE_REPO" \
                "$PROJECT_DOCS_REPO_DIRECTORY" \
                "$PROJECT_DOCS_REPO_BRANCH"
        if [ $? -ne 0 ]; then
                OS::print_status error "setup failed.\n"
                return 1
        fi


        # move existing items to docs repo
        __staging="${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
        __dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_DOCS_REPO_DIRECTORY}"

        OS::print_status info "exporting staging contents to docs repo...\n"
        FS::copy_all "${__staging}/" "$__dest"
        if [ $? -ne 0 ]; then
                OS::print_status error "export failed.\n"
                return 1
        fi

        OS::print_status info "Sourcing commit id for tagging...\n"
        __tag="$(GIT::get_latest_commit_id)"
        if [ -z "$__tag" ]; then
                OS::print_status error "Source failed.\n"
                return 1
        fi

        __current_path="$PWD" && cd "${__dest}"

        OS::print_status info "Committing docs repo...\n"
        GIT::autonomous_force_commit \
                "$__tag" \
                "$PROJECT_DOCS_REPO_KEY" \
                "$PROJECT_DOCS_REPO_BRANCH"
        __exit=$?

        cd "$__current_path" && unset __current_path

        if [ $__exit -ne 0 ]; then
                OS::print_status error "commit failed.\n"
                return 1
        fi


        # report status
        return 0
}
