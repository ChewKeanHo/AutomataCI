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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/changelog.sh"




PACKAGE::run_changelog() {
        __changelog_md="$1"
        __changelog_deb="$2"

        OS::print_status info "checking changelog functions availability...\n"
        CHANGELOG::is_available
        if [ $? -ne 0 ]; then
                OS::print_status error "checking failed.\n"
                return 1
        fi

        # validate input
        OS::print_status info "validating ${PROJECT_VERSION} data changelog entry...\n"
        CHANGELOG::compatible_data_version \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                OS::print_status error "validation failed - existing entry.\n"
                return 1
        fi

        OS::print_status info "validating ${PROJECT_VERSION} deb changelog entry...\n"
        CHANGELOG::compatible_deb_version \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                OS::print_status error "validation failed - there is an existing entry.\n"
                return 1
        fi

        # assemble changelog
        OS::print_status info "assembling markdown changelog...\n"
        CHANGELOG::assemble_md \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
                "$__changelog_md" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                OS::print_status error "assembly failed.\n"
                return 1
        fi

        OS::print_status info "assembling deb changelog...\n"
        mkdir -p "${__changelog_deb%/*}"
        CHANGELOG::assemble_deb \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/changelog" \
                "$__changelog_deb" \
                "$PROJECT_VERSION"
        if [ $? -ne 0 ]; then
                OS::print_status error "assembly failed.\n"
                return 1
        fi

        # report status
        return 0
}
