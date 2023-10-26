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




RELEASE::run_static_repo_conclude() {
        # validate input
        OS::print_status info "Sourcing commit id for tagging...\n"
        __tag="$(GIT::get_latest_commit_id)"
        if [ -z "$__tag" ]; then
                OS::print_status error "Source failed.\n"
                return 1
        fi


        # execute
        __current_path="$PWD"
        cd "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_STATIC_REPO_DIRECTORY}"

        OS::print_status info "Generate required notice file...\n"
        FS::write_file "Home.md" "\
# ${PROJECT_NAME} Static Distribution Repository

This is a re-purposed repository for housing various distribution ecosystem
such as but not limited to \`.deb\`, \`.rpm\`, \`.flatpak\`, and etc for folks
to \`apt-get install\`, \`yum install\`, or \`flatpak install\`.
"


        OS::print_status info "Committing release repo...\n"
        GIT::autonomous_force_commit \
                "$__tag" \
                "$PROJECT_STATIC_REPO_KEY" \
                "$PROJECT_STATIC_REPO_BRANCH"
        __exit=$?

        cd "$__current_path" && unset __current_path


        # report status
        if [ $__exit -ne 0 ]; then
                return 1
        fi

        return 0
}




RELEASE::run_static_repo_setup() {
        # clean up base directory
        OS::print_status info "safety checking static repo release directory...\n"
        if [ -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" ]; then
                OS::print_status error "check failed.\n"
                return 1
        fi
        FS::make_directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}"


        # execute
        OS::print_status info "setting up release static repo...\n"
        INSTALLER::setup_resettable_repo \
                "$PROJECT_PATH_ROOT" \
                "$PROJECT_PATH_RELEASE" \
                "$PWD" \
                "$PROJECT_STATIC_REPO" \
                "$PROJECT_SIMULATE_RELEASE_REPO" \
                "$PROJECT_STATIC_REPO_DIRECTORY"
        if [ $? -ne 0 ]; then
                OS::print_status error "setup failed.\n"
                return 1
        fi


        # move existing items to static repo
        __staging="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${PROJECT_PATH_RELEASE}"
        __dest="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_STATIC_REPO_DIRECTORY}"
        if [ -d "$__staging" ]; then
                OS::print_status info "exporting staging contents to static repo...\n"
                FS::copy_all "${__staging}/" "$__dest"
                if [ $? -ne 0 ]; then
                        OS::print_status error "export failed.\n"
                        return 1
                fi
        fi


        # report status
        return 0
}
