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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-tech-processors_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-deb_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-rpm_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-docker_unix-any.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/_release-pypi_unix-any.sh"




# execute
RELEASE::initiate
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE::run_release_repo_setup
if [ $? -ne 0 ]; then
        OS::print_status error "Check failed.\n"
        return 1
fi


RELEASE::run_pre_processors
if [ $? -ne 0 ]; then
        return 1
fi


for TARGET in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_PKG}"/*; do
        OS::print_status info "processing ${TARGET}\n"

        RELEASE::run_deb \
                "$TARGET" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_LOG}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_rpm \
                "$TARGET" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_docker \
                "$TARGET" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        RELEASE::run_pypi \
                "$TARGET" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RELEASE}" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}"
        if [ $? -ne 0 ]; then
                return 1
        fi
done


RELEASE::run_checksum_seal
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE::run_post_processors
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE::run_release_repo_conclude
if [ $? -ne 0 ]; then
        return 1
fi


RELEASE::run_changelog_conclude
if [ $? -ne 0 ]; then
        return 1
fi




# report status
OS::print_status success "\n\n"
return 0
