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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/docker.sh"




INSTALLER::setup() {
        # validate input
        OS::is_command_available "curl"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "brew"
        if [ $? -eq 0 ]; then
                return 0
        fi

        # execute
        /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ $? -ne 0 ]; then
                return 1
        fi

        case "$PROJECT_OS" in
        linux)
                __location="/home/linuxbrew/.linuxbrew/bin/brew"
                ;;
        darwin)
                __location="/usr/local/bin/brew"
                ;;
        *)
                return 1
                ;;
        esac

        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                if [ "$__line" = "eval \"\$(${__location} shellenv)\"" ]; then
                        unset __location
                        break
                fi
        done < "${HOME}/.bash_profile"


        if [ ! -z "$__location" ]; then
                printf -- "eval \"\$(${__location} shellenv)\"" >> "${HOME}/.bash_profile"
                if [ $? -ne 0 ]; then
                        return 1
                fi

                eval "$(${__location} shellenv)"
        fi

        OS::is_command_available "brew"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




INSTALLER::setup_curl() {
        # validate input
        OS::is_command_available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "curl"
        if [ $? -eq 0 ]; then
                return 0
        fi

        # execute
        brew install curl

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




INSTALLER::setup_docker() {
        # validate input
        OS::is_command_available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "docker"
        if [ $? -ne 0 ]; then
                # NOTE: do nothing since docker requires host to provide anyway.
                return 0
        fi

        # execute
        DOCKER::setup_builder_multiarch
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




INSTALLER::setup_python() {
        # validate input
        OS::is_command_available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "python"
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS::is_command_available "python3"
        if [ $? -eq 0 ]; then
                return 0
        fi

        # execute
        brew install python

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




INSTALLER::setup_reprepro() {
        # validate input
        OS::is_command_available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "reprepro"
        if [ $? -eq 0 ]; then
                return 0
        fi

        # execute
        brew install reprepro

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}