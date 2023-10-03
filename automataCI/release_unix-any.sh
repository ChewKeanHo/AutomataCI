#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-functions_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-rpm_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-docker_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-pypi_unix-any.sh"




# execute
RELEASE::initiate
if [ $? -ne 0 ]; then
        return 1
fi


__recipe="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}"
__recipe="${__recipe}/release_unix-any.sh"
FS::is_file "$__recipe"
if [ $? -eq 0 ]; then
        OS::print_status info "Baseline source detected. Parsing job recipe: ${__recipe}\n"
        . "$__recipe"
        if [ $? -ne 0 ]; then
                OS::print_status error "Parse failed.\n"
                return 1
        fi
fi


if [ ! -z "$PROJECT_PYTHON" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/release_unix-any.sh"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "Python tech detected. Parsing job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Parse failed.\n"
                        return 1
                fi
        fi
fi


if [ ! -z "$PROJECT_GO" ]; then
        __recipe="${PROJECT_PATH_ROOT}/${PROJECT_GO}/${PROJECT_PATH_CI}"
        __recipe="${__recipe}/release_unix-any.sh"
        FS::is_file "$__recipe"
        if [ $? -eq 0 ]; then
                OS::print_status info "Go tech detected. Parsing job recipe: ${__recipe}\n"
                . "$__recipe"
                if [ $? -ne 0 ]; then
                        OS::print_status error "Parse failed.\n"
                        return 1
                fi
        fi
fi


OS::is_command_available "RELEASE::run_pre_processors"
if [ $? -eq 0 ]; then
        RELEASE::run_pre_processors
        if [ $? -ne 0 ]; then
                return 1
        fi
fi


STATIC_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_STATIC_REPO_DIRECTORY}"


RELEASE::run_release_repo_setup
if [ $? -ne 0 ]; then
        return 1
fi


for TARGET in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"/*; do
        OS::print_status info "processing ${TARGET}\n"

        RELEASE::run_deb "$TARGET" "$STATIC_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_rpm \
                "$TARGET" \
                "$STATIC_REPO" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_docker \
                "$TARGET" \
                "$STATIC_REPO" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_pypi \
                "$TARGET" \
                "$STATIC_REPO" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi
done


RELEASE::run_checksum_seal "$STATIC_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


OS::is_command_available "RELEASE::run_post_processors"
if [ $? -eq 0 ]; then
        RELEASE::run_post_processors
        if [ $? -ne 0 ]; then
                return 1
        fi
fi


if [ ! -z "$PROJECT_SIMULATE_RELEASE_REPO" ]; then
        OS::print_status warning "Simulating release repo conclusion...\n"
        OS::print_status warning "Simulating changelog conclusion...\n"
else
        RELEASE::run_release_repo_conclude
        if [ $? -ne 0 ]; then
                return 1
        fi


        RELEASE::run_changelog_conclude
        if [ $? -ne 0 ]; then
                return 1
        fi
fi




# report status
OS::print_status success "\n\n"
return 0
