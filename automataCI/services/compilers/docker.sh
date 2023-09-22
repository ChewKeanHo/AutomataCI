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




DOCKER::amend_manifest() {
        #__tag="$1"
        #__list="$2"

        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        # execute
        BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker manifest create "$1" $2
        if [ $? -ne 0 ]; then
                return 1
        fi

        BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker manifest push "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}



DOCKER::check_login() {
        # validate input
        if [ -z "$CONTAINER_USERNAME" ] || [ -z "$CONTAINER_PASSWORD" ]; then
                return 1
        fi

        # report status
        return 0
}



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
        __tag="$(DOCKER::get_id "$__repo" "$__sku" "$__version" "$__os" "$__arch")"

        FS::is_file "$__dockerfile"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        DOCKER::login "$__repo"
        if [ $? -ne 0 ]; then
                DOCKER::logout
                return 1
        fi

        BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker buildx build \
                --platform "${__os}/${__arch}" \
                --file "$__dockerfile" \
                --tag "$__tag" \
                --provenance=false \
                --sbom=false \
                --label "org.opencontainers.image.ref.name=${__tag}" \
                --push \
                .
        if [ $? -ne 0 ]; then
                DOCKER::logout
                return 1
        fi

        DOCKER::logout
        if [ $? -ne 0 ]; then
                return 1
        fi

        DOCKER::stage "$__destination" "$__os" "$__arch" "$__tag"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




DOCKER::get_builder_id() {
        printf "multiarch"
}




DOCKER::get_id() {
        #__repo="$1"
        #__sku="$2"
        #__version="$3"
        #__os="$4"
        #__arch="$5"

        # validate input
        if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
                return 1
        fi

        # execute
        if [ ! -z "$4" ] && [ ! -z "$5" ]; then
                printf "$(STRINGS::to_lowercase "${1}/${2}:${4}-${5}_${3}")"
        elif [ -z "$4" ] && [ ! -z "$5" ]; then
                printf "$(STRINGS::to_lowercase "${1}/${2}:${5}_${3}")"
        elif [ ! -z "$4" ] && [ -z "$5" ]; then
                printf "$(STRINGS::to_lowercase "${1}/${2}:${4}_${3}")"
        else
                printf "$(STRINGS::to_lowercase "${1}/${2}:${3}")"
        fi

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

        docker buildx inspect "$(DOCKER::get_builder_id)" &> /dev/null
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




DOCKER::is_valid() {
        #__target="$1"

        # execute
        if [ ! -f "$1" ]; then
                return 1
        fi

        if [ "${1##*/}" = "docker.txt" ]; then
                return 0
        fi

        # report status
        return 1
}




DOCKER::login() {
        #__repo="$1"

        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        DOCKER::check_login
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        printf "$CONTAINER_PASSWORD" \
                | docker login "$1" \
                        --username "$CONTAINER_USERNAME" \
                        --password-stdin

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




DOCKER::logout() {
        # execute
        docker logout && rm -f "${HOME}/.docker/config.json" &> /dev/null

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




DOCKER::release() {
        __target="$1"
        __directory="$2"
        __datastore="$3"
        __version="$4"

        # validate input
        if [ -z "$__target" ] ||
                [ -z "$__directory" ] ||
                [ -z "$__datastore" ] ||
                [ -z "$__version" ] ||
                [ ! -f "$__target" ] ||
                [ ! -d "$__directory" ] ||
                [ ! -d "$__datastore" ]; then
                return 1
        fi


        # execute
        __list=""
        __repo=""
        __sku=""
        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                if [ -z "$__line" ] || [ "$__line" == "\n" ]; then
                        continue
                fi

                __entry="${__line##* }"
                __repo="${__entry%%:*}"
                __sku="${__repo##*/}"
                __repo="${__repo%/*}"

                if [ ! -z "$__list" ]; then
                        __list="${__list} "
                fi
                __list="${__list}--amend $__entry"
        done < "$__target"
        IFS="$old_IFS" && unset old_IFS __line

        if [ -z "$__list" ] || [ -z "$__repo" ] || [ -z "$__sku" ]; then
                return 1
        fi

        DOCKER::login "$__repo"
        if [ $? -ne 0 ]; then
                DOCKER::logout
                return 1
        fi

        DOCKER::amend_manifest "$(DOCKER::get_id "$__repo" "$__sku" "latest")" "$__list"
        if [ $? -ne 0 ]; then
                DOCKER::logout
                return 1
        fi

        DOCKER::amend_manifest "$(DOCKER::get_id "$__repo" "$__sku" "$__version")" "$__list"
        if [ $? -ne 0 ]; then
                DOCKER::logout
                return 1
        fi

        DOCKER::logout
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




DOCKER::setup_builder_multiarch() {
        # validate input
        DOCKER::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        __name="$(DOCKER::get_builder_id)"

        docker buildx inspect "${__name}" &> /dev/null
        if [ $? -eq 0 ]; then
                return 0
        fi

        docker buildx create --use --name "${__name}"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




DOCKER::stage() {
        #__target="$1"
        #__os="$2"
        #__arch="$3"
        #__tag="$4"

        # validate input
        if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
                return 1
        fi

        # execute
        FS::append_file "$1" "${2} ${3} ${4}\n"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}
