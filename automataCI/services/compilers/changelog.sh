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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compress/gz.sh"




CHANGELOG::assemble_deb() {
        __directory="$1"
        __target="$2"
        __version="$3"

        # validate input
        if [ -z "$__directory" ] || [ -z "$__target" ] || [ -z "$__version" ]; then
                return 1
        fi

        __directory="${__directory}/deb"
        __target="${__target%.gz*}"

        # assemble file
        FS::remove_silently "$__target"
        FS::remove_silently "${__target}.gz"
        FS::make_housing_directory "$__target"

        __initiated=""
        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                FS::append_file "$__target" "$__line\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                __initiated="true"
        done < "${__directory}/latest"

        for __tag in $(git tag --sort -version:refname); do
                if [ ! -f "${__directory}/${__tag##*v}" ]; then
                        continue
                fi

                if [ ! -z "$__initiated" ]; then
                        FS::append_file "$__target" "\n\n"
                fi

                while IFS="" read -r __line || [ -n "$__line" ]; do
                        FS::append_file "$__target" "$__line\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi

                        __initiated="true"
                done < "${__directory}/${__tag##*v}"
        done
        IFS="$old_IFS"
        unset old_IFS __line __tag

        # gunzip
        GZ::create "$__target"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




CHANGELOG::assemble_md() {
        __directory="$1"
        __target="$2"
        __version="$3"
        __title="$4"

        # validate input
        if [ -z "$__directory" ] ||
                [ -z "$__target" ] ||
                [ -z "$__version" ] ||
                [ -z "$__title" ]; then
                return 1
        fi

        __directory="${__directory}/data"

        # assemble file
        FS::remove_silently "$__target"
        FS::make_housing_directory "$__target"
        FS::write_file "$__target" "# ${__title}\n\n"
        FS::append_file "$__target" "\n## ${__version}\n\n"
        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                FS::append_file "$__target" "* ${__line}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done < "${__directory}/latest"

        for __tag in $(git tag --sort -version:refname); do
                if [ ! -f "${__directory}/${__tag##*v}" ]; then
                        continue
                fi

                FS::append_file "$__target" "\n\n## ${__tag}\n\n"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        FS::append_file "$__target" "* ${__line}\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                done < "${__directory}/${__tag##*v}"
        done
        IFS="$old_IFS"
        unset old_IFS __line __tag

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




CHANGELOG::assemble_rpm() {
        __target="$1"
        __resources="$2"
        __date="$3"
        __name="$4"
        __email="$5"
        __version="$6"
        __cadence="$7"

        # validate input
        if [ -z "$__target" ] ||
                [ -z "$__resources" ] ||
                [ -z "$__date" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__version" ] ||
                [ -z "$__cadence" ] ||
                [ ! -f "$__target" ] ||
                [ ! -d "$__resources" ]; then
                return 1
        fi

        # emit stanza
        FS::append_file "$__target" "%%changelog\n"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # emit latest changelog
        if [ -f "${__resources}/changelog/data/latest" ]; then
                FS::append_file "$__target" \
                        "* ${__date} ${__name} <${__email}> - ${__version}-${__cadence}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                __old_IFS="$IFS"
                while IFS="" read -r __line || [ -n "$__line" ]; do
                        __line="${__line%%#*}"
                        if [ -z "$__line" ]; then
                                continue
                        fi

                        FS::append_file "$__target" "- ${__line}\n"
                        if [ $? -ne 0 ]; then
                                return 1
                        fi
                done < "${__resources}/changelog/data/latest"
                IFS="$__old_IFS" && unset __old_IFS __line
        else
                FS::append_file "$__target" "# unavailable\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi

        # emit tailing newline
        FS::append_file "$__target" "\n"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




CHANGELOG::build_data_entry() {
        __directory="$1"

        # validate input
        if [ -z "$__directory" ]; then
                return 1
        fi

        # get last tag from git log
        __tag="$(git rev-list --tags --max-count=1)"
        if [ -z "$__tag" ]; then
                __tag="$(git rev-list --max-parents=0 --abbrev-commit HEAD)"
        fi

        # generate log file from the latest to the last tag
        __directory="${__directory}/data"
        FS::make_directory "$__directory"
        git log --pretty=format:"%s" HEAD..."$__tag" > "${__directory}/.latest"
        if [ ! -f "${__directory}/.latest" ]; then
                return 1
        fi

        # good file, update the previous
        FS::remove_silently "${__directory}/latest" &> /dev/null
        FS::move "${__directory}/.latest" "${__directory}/latest"

        # report verdict
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
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
                [ ! -f "${__directory}/data/latest" ] ||
                [ -z "$__sku" ] ||
                [ -z "$__dist" ] ||
                [ -z "$__urgency" ] ||
                [ -z "$__name" ] ||
                [ -z "$__email" ] ||
                [ -z "$__date" ]; then
                return 1
        fi

        case "$__dist" in
        stable|unstable|testing|experimental)
                ;;
        *)
                return 1
                ;;
        esac

        # all good. Generate the log fragment
        FS::make_directory "${__directory}/deb"

        # create the entry header
        FS::append_file "${__directory}/deb/.latest" "\
${__sku} (${__version}) ${__dist}; urgency=${__urgency}

"

        # generate body line-by-line
        old_IFS="$IFS"
        while IFS="" read -r line || [ -n "$line" ]; do
                line="${line::80}"
                FS::append_file "${__directory}/deb/.latest" "  * ${line}\n"
        done < "${__directory}/data/latest"
        IFS="$old_IFS"
        unset line old_IFS
        FS::append_file "${__directory}/deb/.latest" "\n"

        # create the entry signed-off
        FS::append_file "${__directory}/deb/.latest" \
                "-- ${__name} <${__email}>  ${__date}\n"

        # good file, update the previous
        FS::move "${__directory}/deb/.latest" "${__directory}/deb/latest"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi
        return 1
}




CHANGELOG::compatible_data_version() {
        __directory="$1"
        __version="$2"

        if [ -z "$__directory" ] || [ -z "$__version" ]; then
                return 1
        fi

        if [ ! -f "${__directory}/data/${__version}" ]; then
                return 0
        fi

        return 1
}




CHANGELOG::compatible_deb_version() {
        __directory="$1"
        __version="$2"

        if [ -z "$__directory" ] || [ -z "$__version" ]; then
                return 1
        fi

        if [ ! -f "${__directory}/deb/${__version}" ]; then
                return 0
        fi

        return 1
}




CHANGELOG::is_available() {
        if [ -z "$(type -t git)" ]; then
                return 1
        fi

        GZ::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}




CHANGELOG::seal() {
        __directory="$1"
        __version="$2"

        # validate input
        if [ -z "$__directory" ] || [ -z "$__version" ] || [ ! -d "$__directory" ]; then
                return 1
        fi

        if [ ! -f "${__directory}/data/latest" ]; then
                return 1
        fi

        if [ ! -f "${__directory}/deb/latest" ]; then
                return 1
        fi

        # execute
        FS::move "${__directory}/data/latest" "${__directory}/data/${__version}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::move "${__directory}/deb/latest" "${__directory}/deb/${__version}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}
