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
CHANGELOG::is_available() {
        if [ -z "$(type -t git)" ]; then
                return 1
        fi

        return 0
}

CHANGELOG::build_data_entry() {
        __directory="$1"
        __version="$2"

        # set to latest if not available
        if [ -z "$__version" ]; then
                __version="latest"
        fi

        # get last tag from git log
        __last_tag="$(git rev-list --tags --max-count=1)"
        if [ -z "$__last_tag" ]; then
                __last_tag="$(git rev-list --max-parents=0 --abbrev-commit HEAD)"
        fi

        # generate log file from the latest to the last tag
        __directory="${__directory}/data"
        mkdir -p "$__directory"
        git log --pretty=format:"%s" HEAD..."$__last_tag" > "${__directory}/.${__version}"
        if [ ! -f "${__directory}/.${__version}" ]; then
                unset __directory __version __last_tag
                return 1
        fi

        # good file, update the previous
        mv "${__directory}/.${__version}" "${__directory}/${__version}"
        __exit=$?

        # report verdict
        unset __directory __version __last_tag
        return $__exit
}

CHANGELOG::build_deb_entry() {
        __directory="$1"
        __version="$2"
        __sku="$3"
        __dist="$4"
        __urgency="$5"
        __name="$6"
        __email="$7"
        __date="$8"

        if [ -z "$__version" ]; then
                __version="latest"
        fi

        if [ ! -f "${__directory}/data/${__version}" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__dist" ] ||
                [ -z "$__urgency" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__date" ]; then
                unset __directory \
                        __version \
                        __sku \
                        __dist \
                        __urgency \
                        __name \
                        __email \
                        __date
                return 1
        fi

        # all good. Generate the log fragment
        mkdir -p "${__directory}/deb"

        # create the entry header
        printf "\
${__sku} (${__version}) ${__dist}; urgency=${__urgency}
" > "${__directory}/deb/.${__version}"

        # generate body line-by-line
        printf "\n" >> "${__directory}/deb/.${__version}"
        old_IFS="$IFS"
        while IFS="" read -r line || [ -n "$line" ]; do
                line="${line::80}"
                printf "  * $line\n" >> "${__directory}/deb/.${__version}"
        done < "${__directory}/data/${__version}"
        IFS="$old_IFS"
        unset line old_IFS
        printf "\n" >> "${__directory}/deb/.${__version}"

        # create the entry signed-off
        printf -- "-- ${__name} <${__email}>  ${__date}\n" \
                >> "${__directory}/deb/.${__version}"

        # good file, update the previous
        mv "${__directory}/deb/.${__version}" "${__directory}/deb/${__version}"
        __exit=$?

        # report status
        unset __directory \
                __version \
                __sku \
                __dist \
                __urgency \
                __name \
                __email \
                __date
        return $__exit
}
