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



GO_Activate_Local_Environment() {
        # validate input
        GO_Is_Available
        if [ $? -ne 0 ] ; then
                return 1
        fi

        GO_Is_Localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        ___location="$(GO_Get_Activator_Path)"
        FS_Is_File "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        . "$___location"
        GO_Is_Localized
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




GO_Get_Activator_Path() {
        ___location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_GO_ENGINE}/activate.sh"
        printf -- "%b" "$___location"
}




GO_Is_Available() {
        # execute
        OS_Is_Command_Available "go"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




GO_Is_Localized() {
        # execute
        if [ $(STRINGS_Is_Empty "$PROJECT_GO_LOCALIZED") -ne 0 ] ; then
                return 0
        fi


        # report status
        return 1
}




GO_Setup() {
        # validate input
        GO_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        brew install go
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GO_Setup_Local_Environment() {
        # validate input
        GO_Is_Localized
        if [ $? -eq 0 ] ; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_ROOT") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_TOOLS") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_GO_ENGINE") -eq 0 ]; then
                return 1
        fi

        GO_Is_Available
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # execute
        ___label="($PROJECT_PATH_GO_ENGINE)"
        ___location="$(GO_Get_Activator_Path)"

        if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
                ___brew="eval \$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
                ___brew="eval \$(/usr/local/bin/brew shellenv)"
        else
                ___brew=""
        fi

        FS_Make_Housing_Directory "$___location"
        FS_Make_Directory "${___location%/*}/bin"
        FS_Make_Directory "${___location%/*}/cache"
        FS_Make_Directory "${___location%/*}/env"
        FS_Write_File "${___location}" "\
#!/bin/sh
if [ -z \"\$(type -t 'go')\" ]; then
        1>&2 printf -- '[ ERROR ] missing go compiler.\\\\n'
        return 1
fi

deactivate() {
        export GOPATH='$(go env GOPATH)'
        export GOBIN='$(go env GOBIN)'
        export GOCACHE='$(go env GOCACHE)'
        export GOENV='$(go env GOENV)'
        export PS1=\"\${PS1##*${___label} }\"
        unset PROJECT_GO_LOCALIZED
        return 0
}

# check
if [ ! -z \"\$PROJECT_GO_LOCALIZED\" ]; then
        return 0
fi

# activate
${___brew}
export GOPATH='${___location%/*}'
export GOBIN='${___location%/*}/bin'
export GOCACHE='${___location%/*}/cache'
export GOENV='${___location%/*}/env'
export PROJECT_GO_LOCALIZED='${___location}'
export PS1=\"${___label} \${PS1}\"
return 0
"

        FS_Is_File "${___location}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # testing the activation
        GO_Activate_Local_Environment
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # report status
        return 0
}
