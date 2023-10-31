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

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-cargo_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-changelog_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-checksum_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-chocolatey_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-docker_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-homebrew_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-pypi_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-rpm_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-staticrepo_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-docsrepo_unix-any.sh"




# execute
RELEASE::initiate_checksum
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


OS::is_command_available "RELEASE::run_pre_processor"
if [ $? -eq 0 ]; then
        RELEASE::run_pre_processor
        if [ $? -ne 0 ]; then
                return 1
        fi
fi


RELEASE::run_static_repo_setup
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE::run_homebrew_repo_setup
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE::run_chocolatey_repo_setup
if [ $? -ne 0 ]; then
        return 1
fi


STATIC_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_STATIC_REPO_DIRECTORY}"
HOMEBREW_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_HOMEBREW_DIRECTORY}"
CHOCOLATEY_REPO="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}/${PROJECT_CHOCOLATEY_DIRECTORY}"
for TARGET in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"/*; do
        if [ "${TARGET%.asc*}" != "$TARGET" ]; then
                continue
        fi
        OS::print_status info "processing ${TARGET}\n"

        RELEASE::run_deb "$TARGET" "$STATIC_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_rpm "$TARGET" "$STATIC_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_docker "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_pypi "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_cargo "$TARGET"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_homebrew "$TARGET" "$HOMEBREW_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_chocolatey "$TARGET" "$CHOCOLATEY_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "RELEASE::run_package_processor"
        if [ $? -eq 0 ]; then
                RELEASE::run_package_processor "$TARGET"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi
done


RELEASE::run_checksum_seal "$STATIC_REPO"
if [ $? -ne 0 ]; then
        return 1
fi


OS::is_command_available "RELEASE::run_post_processor"
if [ $? -eq 0 ]; then
        RELEASE::run_post_processor
        if [ $? -ne 0 ]; then
                return 1
        fi
fi


if [ ! -z "$PROJECT_SIMULATE_RELEASE_REPO" ]; then
        OS::print_status warning "simulating release repo conclusion...\n"
        OS::print_status warning "simulating changelog conclusion...\n"
else
        RELEASE::run_static_repo_conclude
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_homebrew_repo_conclude "$HOMEBREW_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_chocolatey_repo_conclude "$CHOCOLATEY_REPO"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_changelog_conclude
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::docs_repo
        if [ $? -ne 0 ]; then
                return 1
        fi
fi




# report status
OS::print_status success "\n\n"
return 0
