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




GIT::is_available() {
        OS::is_command_available "git"
        if [ $? -ne 0 ]; then
                return 1
        fi

        return 0
}




GIT::clone() {
        #__url="$1"
        #__name="$2"

        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        GIT::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ ! -z "$2" ]; then
                if [ -f "$2" ]; then
                        return 1
                fi

                if [ -d "$2" ]; then
                        return 2
                fi
        fi

        # execute
        if [ ! -z "$2" ]; then
                git clone "$1" "$2"
        else
                git clone "$1"
        fi

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}




GIT::get_latest_commit_id() {
        # validate input
        GIT::is_available
        if [ $? -ne 0 ]; then
                printf ""
                return 1
        fi

        # execute
        __tag="$(git rev-list --max-parents=0 --abbrev-commit HEAD)"
        if [ ! -z "$__tag" ]; then
                printf -- "$__tag"
                return 0
        else
                printf ""
                return 1
        fi
}




GIT::hard_reset_to_init() {
        # validate input
        GIT::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        __first="$(git rev-list --max-parents=0 --abbrev-commit HEAD)"
        if [ "$__first" = "" ]; then
                return 1
        fi

        git reset --hard "$__first"
        if [ $? -ne 0 ]; then
                return 1
        fi

        git clean -fd
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




GIT::autonomous_force_commit() {
        #__tracker="$1"
        #__repo="$2"
        #__branch="$3"

        # validate input
        if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
                return 1
        fi

        GIT::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        git add .
        if [ $? -ne 0 ]; then
                return 1
        fi

        git commit -m "Publish as of ${1}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        git push -f "$2" "$3"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




GIT::remove_worktree() {
        #__destination="$1"

        # validate input
        if [ -z "$1" ]; then
                return 1
        fi

        GIT::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        git worktree remove "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS::remove_silently "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




GIT::setup_worktree() {
        #__branch="$1"
        #__destination="$2"

        # validate input
        if [ -z "$1" ] || [ -z "$2" ]; then
                return 1
        fi

        GIT::is_available
        if [ $? -ne 0 ]; then
                return 1
        fi

        # execute
        FS::make_directory "$2"
        git worktree add "$2" "$1"

        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}
