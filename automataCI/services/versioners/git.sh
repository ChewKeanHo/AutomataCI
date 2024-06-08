#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




GIT_At_Root_Repo() {
        #___directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS_Is_File "${1}/.git/config"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Autonomous_Commit() {
        #___tracker="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$(git status --porcelain)") -eq 0 ]; then
                return 0 # nothing to commit
        fi


        # execute
        git add .
        if [ $? -ne 0 ]; then
                return 1
        fi

        git commit -m "automation: published as of ${1}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Autonomous_Force_Commit() {
        #___tracker="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$(git status --porcelain)") -eq 0 ]; then
                return 0 # nothing to commit
        fi


        # execute
        git add .
        if [ $? -ne 0 ]; then
                return 1
        fi

        git commit -m "automation: published as of ${1}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Change_Branch() {
        #___branch="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        git checkout "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Clone() {
        #___url="$1"
        #___name="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$2") -ne 0 ]; then
                FS_Is_File "$2"
                if [ $? -eq 0 ]; then
                        return 1
                fi

                FS_Is_Directory "$2"
                if [ $? -eq 0 ]; then
                        return 2
                fi
        fi


        # execute
        if [ $(STRINGS_Is_Empty "$2") -ne 0 ]; then
                git clone "$1" "$2"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        else
                git clone "$1"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        # report status
        return 0
}




GIT_Clone_Repo() {
        ___root="$1"
        ___relative_path="$2"
        ___current="$3"
        ___git_repo="$4"
        ___simulate="$5"
        ___label="$6"
        ___branch="$7"
        ___reset="$8"


        # validate input
        if [ $(STRINGS_Is_Empty "$___root") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___relative_path") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___current") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___git_repo") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___label") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___path="${___root}/${___relative_path}"
        FS_Make_Directory "$___path"
        ___path="${___path}/${___label}"

        FS_Is_Directory "$___path"
        if [ $? -eq 0 ]; then
                cd "${___path}"
                ___directory="$(GIT_Get_Root_Directory)"
                cd "$___current"

                if [ "$___directory" = "$___root" ]; then
                        FS_Remove_Silently "${___path}"
                fi
        fi


        if [ $(STRINGS_Is_Empty "$___simulate") -ne 0 ]; then
                FS_Make_Directory "${___path}"
                cd "${___path}"
                git init --initial-branch=main
                git commit --allow-empty -m "Initial Commit"
                cd "$___current"
                return 0
        else
                cd "${___path%/*}"
                GIT_Clone "$___git_repo" "$___label"
                case $? in
                0|2)
                        # Accepted
                        ;;
                *)
                        return 1
                        ;;
                esac
                cd "$___current"
        fi


        # switch branch if available
        if [ $(STRINGS_Is_Empty "$___branch") -ne 0 ]; then
                cd "${___path}"
                GIT_Change_Branch "$___branch"
                if [ $? -ne 0 ]; then
                        cd "$___current"
                        return 1
                fi
                cd "$___current"
        fi


        # hard reset
        if [ $(STRINGS_Is_Empty "$___reset") -ne 0 ]; then
                cd "${___path}"
                GIT_Hard_Reset_To_Init "$___root"
                if [ $? -ne 0 ]; then
                        cd "$___current"
                        return 1
                fi
                cd "$___current"
        fi


        # report status
        return 0
}




GIT_Get_First_Commit_ID() {
        # validate input
        GIT_Is_Available
        if [ $? -ne 0 ]; then
                printf ""
                return 1
        fi


        # execute
        printf -- "$(git rev-list --max-parents=0 --abbrev-commit HEAD)"


        # report status
        return 0
}




GIT_Get_Latest_Commit_ID() {
        # validate input
        GIT_Is_Available
        if [ $? -ne 0 ]; then
                printf ""
                return 1
        fi


        # execute
        printf -- "$(git rev-parse HEAD)"


        # report status
        return 0
}




GIT_Get_Remote_URL() {
        #___remote="$1"

        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi


        # execute
        printf -- "%s" "$(git remote get-url "$1")"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Get_Root_Directory() {
        # validate input
        GIT_Is_Available
        if [ $? -ne 0 ]; then
                printf ""
                return 1
        fi


        # execute
        printf -- "$(git rev-parse --show-toplevel)"


        # report status
        return 0
}




GIT_Hard_Reset_To_Init() {
        #___root="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # CVE-2023-42798 - Make sure the directory is not the same as the root
        #                  directory. If it does, bail out immediately and DO
        #                  not proceed.
        ___first="$(GIT_Get_Root_Directory)"
        if [ $(STRINGS_Is_Empty "$___first") -eq 0 ]; then
                return 1
        fi

        if [ "$___first" = "$1" ]; then
                return 1
        fi


        # execute
        ___first="$(GIT_Get_First_Commit_ID)"
        if [ "$___first" = "" ]; then
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




GIT_Is_Available() {
        # execute
        OS_Is_Command_Available "git"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Pull_To_Latest() {
        # validate input
        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        git pull --rebase
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Push() {
        #___repo="$1"
        #___branch="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        git push "$1" "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Push_Specific() {
        #___workspace="$1"
        #___remote="$2"
        #___source="$3"
        #___target="$4"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$2") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$3") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$4") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___current_path="$PWD" && cd "$1"
        git push -f "$2" "$3":"$4"
        ___process=$?
        cd "$___current_path" && unset ___current_path
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Remove_Worktree() {
        #___destination="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        git worktree remove "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Remove_Silently "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Setup_Worktree() {
        #___branch="$1"
        #___destination="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS_Make_Directory "$2"
        git worktree add "$2" "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GIT_Setup_Workspace_Bare() {
        #___remote="$1"
        #___branch="$2"
        #___destination="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$2") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$3") -eq 0 ]; then
                return 1
        fi

        GIT_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___url="$(GIT_Get_Remote_URL "$1")"
        if [ $(STRINGS_Is_Empty "$___url") -eq 0 ]; then
                return 1
        fi

        FS_Remake_Directory "$3"
        ___current_path="$PWD" && cd "$3"
        git init &> /dev/null
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        git remote add "$1" "$___url"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        git checkout --orphan "$2"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        cd "$___current_path" && unset ___current_path


        # report status
        return 0
}
