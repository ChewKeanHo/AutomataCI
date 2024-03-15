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
        printf -- "%b" "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_GO_ENGINE}/activate.sh"
}




GO_Get_Compiler_Optimization_Arguments() {
        #___os="$1"
        #___arch="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                printf -- ""
                return 1
        fi


        # execute
        ___os="$(STRINGS_To_Lowercase "$1")"
        ___arch="$(STRINGS_To_Lowercase "$2")"
        ___arguments=""

        case "${___os}-${___arch}" in
        android-arm64)
                if [ "$PROJECT_OS" != "darwin" ]; then
                        ___arguments="${___argument} -buildmode=pie"
                fi
                ;;
        darwin-amd64|darwin-arm64)
                ___arguments="${___argument} -buildmode=pie"
                ;;
        linux-amd64|linux-arm64|linux-ppc64le)
                ___arguments="${___argument} -buildmode=pie"
                ;;
        windows-amd64|windows-arm64)
                ___arguments="${___argument} -buildmode=pie"
                ;;
        *)
                ;;
        esac


        # report status
        printf -- "%b" "$(STRINGS_Trim_Whitespace "$___arguments")"
        return 0
}




GO_Get_Filename() {
        #___name="$1"
        #___os="$2"
        #___arch="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$2") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$3") -eq 0 ]; then
                printf -- ""
                return 1
        fi


        # execute
        ___os="$(STRINGS_To_Lowercase "$2")"
        ___arch="$(STRINGS_To_Lowercase "$3")"
        ___filename="${1}_${___os}-${___arch}"

        case "${___os}-${___arch}" in
        js-wasm)
                ___filename="${___filename}.wasm"
                ;;
        wasip1-wasm)
                ___filename="${___filename}.wasi"
                ;;
        windows*)
                ___filename="${___filename}.exe"
                ;;
        *)
                ;;
        esac


        # report status
        printf -- "%b" "$(STRINGS_Trim_Whitespace "$___filename")"
        return 0
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
        FS_Make_Directory "$(FS_Get_Directory "$___location")/bin"
        FS_Make_Directory "$(FS_Get_Directory "$___location")/cache"
        FS_Make_Directory "$(FS_Get_Directory "$___location")/env"
        FS_Write_File "$___location" "\
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
export GOPATH='$(FS_Get_Directory "$___location")'
export GOBIN='$(FS_Get_Directory "$___location")/bin'
export GOCACHE='$(FS_Get_Directory "$___location")/cache'
export GOENV='$(FS_Get_Directory "$___location")/env'
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
