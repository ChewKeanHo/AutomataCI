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

        # validate input
        if [ -z "$__directory" ]; then
                unset __directory
                return 1
        fi

        # get last tag from git log
        __last_tag="$(git rev-list --tags --max-count=1)"
        if [ -z "$__last_tag" ]; then
                __last_tag="$(git rev-list --max-parents=0 --abbrev-commit HEAD)"
        fi

        # generate log file from the latest to the last tag
        __directory="${__directory}/data"
        mkdir -p "$__directory"
        git log --pretty=format:"%s" HEAD..."$__last_tag" > "${__directory}/.latest"
        if [ ! -f "${__directory}/.latest" ]; then
                unset __directory __last_tag
                return 1
        fi

        # good file, update the previous
        mv "${__directory}/.latest" "${__directory}/latest"
        __exit=$?

        # report verdict
        unset __directory __last_tag
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

        # validate input
        if [ -z "$__directory" ] ||
                [ -z "$__version" ] ||
                [ -f "${__directory}/data/${__version}" ] ||
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

        case "$__dist" in
        stable|unstable|testing|experimental)
                ;;
        *)
                unset __directory \
                        __version \
                        __sku \
                        __dist \
                        __urgency \
                        __name \
                        __email \
                        __date
                return 1
                ;;
        esac

        # all good. Generate the log fragment
        mkdir -p "${__directory}/deb"

        # create the entry header
        printf "\
${__sku} (${__version}) ${__dist}; urgency=${__urgency}
" > "${__directory}/deb/.latest"

        # generate body line-by-line
        printf "\n" >> "${__directory}/deb/.latest"
        old_IFS="$IFS"
        while IFS="" read -r line || [ -n "$line" ]; do
                line="${line::80}"
                printf "  * $line\n" >> "${__directory}/deb/.latest"
        done < "${__directory}/data/latest"
        IFS="$old_IFS"
        unset line old_IFS
        printf "\n" >> "${__directory}/deb/.latest"

        # create the entry signed-off
        printf -- "-- ${__name} <${__email}>  ${__date}\n" \
                >> "${__directory}/deb/.latest"

        # good file, update the previous
        mv "${__directory}/deb/.latest" "${__directory}/deb/latest"
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

CHANGELOG::compatible_data_version() {
        __directory="$1"
        __version="$2"

        if [ -z "$__directory" ] || [ -z "$__version" ]; then
                unset __directory __version
                return 1
        fi

        if [ ! -f "${__directory}/data/${__version}" ]; then
                unset __directory __version
                return 0
        fi

        return 1
}

CHANGELOG::compatible_deb_version() {
        __directory="$1"
        __version="$2"

        if [ -z "$__directory" ] || [ -z "$__version" ]; then
                unset __directory __version
                return 1
        fi

        if [ ! -f "${__directory}/deb/${__version}" ]; then
                unset __directory __version
                return 0
        fi

        return 1
}

CHANGELOG::assemble_deb() {
        __directory="$1"
        __target="$2"
        __version="$3"

        if [ -z "$__directory" ] ||
                [ -z "$__target" ] ||
                [ -z "$__version" ]; then
                unset __directory __target __version
                return 1
        fi
        __directory="${__directory}/deb"


        # assemble file
        rm -rf "$__target" "${__target}.gz" &> /dev/null
        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                printf -- "$__line\n" >> "$__target"
        done < "${__directory}/latest"

        for __tag in "$(git tag --sort version:refname)"; do
                if [ ! -f "${__directory}/${__tag}" ]; then
                        continue
                fi

                while IFS="" read -r __line || [ -n "$__line" ]; do
                        printf -- "\n$__line\n" >> "$__target"
                done < "${__directory}/${__tag}"
        done
        IFS="$old_IFS"
        unset old_IFS __line __tag


        # gunzip
        if [ "$(type -t gzip)" ]; then
                gzip -9 "$__target"
                __exit=$?
        elif [ "$(type -t gunzip)" ]; then
                gunzip -9 "$__target"
                __exit=$?
        else
                __exit=1
        fi


        # report status
        unset __directory __target __version
        return $__exit
}

CHANGELOG::assemble_md() {
        __directory="$1"
        __target="$2"
        __version="$3"
        >&2 printf "assemble_md\n"
}
