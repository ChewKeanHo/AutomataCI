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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"




DOCKER::clean_up() {
        # validate input
        DOCKER::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        docker system prune --force

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




DOCKER::create() {
        __destination="$1"
        __os="$2"
        __arch="$3"
        __repo="$4"
        __sku="$5"
        __version="$6"

        # validate input
        if [ -z "${__destination}" ] ||
                [ -z "${__os}" ] ||
                [ -z "${__arch}" ] ||
                [ -z "${__repo}" ] ||
                [ -z "${__sku}" ] ||
                [ -z "${__version}" ]; then
                return 1
        fi

        DOCKER::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        __dockerfile="./Dockerfile"
        __id="$(STRINGS::to_lowercase "${__repo}/${__sku}_${__os}-${__arch}:${__version}")"

        FS::is_file "${__dockerfile}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        docker buildx build \
                --platform "${__os}/${__arch}" \
                --file "${__dockerfile}" \
                --tag "${__id}" \
                .
        if [ $? -ne 0 ]; then
                return 1
        fi

        DOCKER::save_image "$__id" "$__destination"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




DOCKER::is_available() {
        # execute
        OS::is_command_available "docker"
        if [ $? -ne 0 ]; then
                return 1
        fi

        docker ps &> /dev/null
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




DOCKER::save_image() {
        #__id="$1"
        #__destination="$2"

        # validate input
        if [ -z "${__id}" ] || [ -z "${__destination}" ]; then
                return 1
        fi

        DOCKER::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        docker save "$1" > "$__destination"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}
