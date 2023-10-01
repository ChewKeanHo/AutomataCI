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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/c.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/docker.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/versioners/git.sh"




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




INSTALLER::setup_c() {
        #__os="$1"
        #__arch="$2"


        # validate input
        OS::is_command_available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        C::is_available
        if [ $? -eq 0 ]; then
                return 0
        fi

        if [ "$1" = "darwin" ]; then
                brew install \
                        aarch64-elf-gcc \
                        arm-none-eabi-gcc \
                        riscv64-elf-gcc \
                        x86_64-elf-gcc \
                        i686-elf-gcc \
                        mingw-w64 \
                        gcc
        else
                brew install \
                        aarch64-elf-gcc \
                        arm-none-eabi-gcc \
                        riscv64-elf-gcc \
                        x86_64-elf-gcc \
                        i686-elf-gcc \
                        mingw-w64 \
                        llvm \
                        gcc
        fi
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




INSTALLER::setup_docker() {
        # validate input
        OS::is_command_available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        DOCKER::is_available
        if [ $? -ne 0 ]; then
                # NOTE: nothing else can be done since it's host-specific.
                #       DO NOT brew install Docker-Desktop autonomously.
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




INSTALLER::setup_go() {
        # validate input
        OS::is_command_available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS::is_command_available "go"
        if [ $? -eq 0 ]; then
                return 0
        fi

        # execute
        brew install go

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
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




INSTALLER::setup_release_repo() {
        __root="$1"
        __release="$2"
        __current="$3"
        __git_repo="$4"
        __simulate="$5"
        __label="$6"


        # validate input
        if [ -z "$__root" ] ||
                [ -z "$__release" ] ||
                [ -z "$__current" ] ||
                [ -z "$__git_repo" ] ||
                [ -z "$__label" ]; then
                return 1
        fi

        GIT::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS::make_directory "${__root}/${__release}"

        if [ -d "${__root}/${__release}/${__label}" ]; then
                cd "${__root}/${__release}/${__label}"
                __directory="$(GIT::get_root_directory)"
                cd "$__current"

                if [ "$__directory" = "$__root" ]; then
                        FS::remove_silently "${__root}/${__release}/${__label}"
                fi
        fi


        if [ ! -z "$__simulate" ]; then
                FS::make_directory "${__root}/${__release}/${__label}"
                cd "${__root}/${__release}/${__label}"
                git init --initial-branch=main
                git commit --allow-empty -m "Initial Commit"
                cd "$__current"
        else
                cd "${__root}/${__release}"
                GIT::clone "$__git_repo" "$__label"
                case $? in
                0|2)
                        # Accepted
                        ;;
                *)
                        return 1
                        ;;
                esac

                cd "${__root}/${__release}/${__label}"
                GIT::hard_reset_to_init "$__root"
                if [ $? -ne 0 ]; then
                        cd "$__current"
                        return 1
                fi
                cd "$__current"
        fi


        # report status
        return 0
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
