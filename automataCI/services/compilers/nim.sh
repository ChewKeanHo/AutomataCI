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




NIM_Activate_Local_Environment() {
        # validate input
        NIM_Is_Available
        if [ $? -ne 0 ] ; then
                return 1
        fi

        NIM_Is_Localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        ___location="$(NIM_Get_Activator_Path)"
        FS_Is_File "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi

        . "$___location"

        NIM_Is_Localized
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM_Check_Package() {
        #___directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi


        # execute
        ___current_path="$PWD" && cd "$1"
        nimble check
        ___process=$?
        cd "$___current_path" && unset ___current_path
        if [ $___process -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM_Get_Activator_Path() {
        printf -- "%b" "${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_NIM_ENGINE}/activate.sh"
}




NIM_Is_Available() {
        # execute
        OS_Sync

        OS_Is_Command_Available "nim"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "nimble"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM_Is_Localized() {
        # execute
        if [ $(STRINGS_Is_Empty "$PROJECT_NIM_LOCALIZED") -ne 0 ]; then
                return 0
        fi


        # report status
        return 1
}




NIM_Setup() {
        # validate input
        NIM_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi

        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        brew install nim
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM_Setup_Local_Environment() {
        # validate input
        NIM_Is_Localized
        if [ $? -eq 0 ] ; then
                return 0
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_ROOT") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_TOOLS") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$PROJECT_PATH_NIM_ENGINE") -eq 0 ]; then
                return 1
        fi

        NIM_Is_Available
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # execute
        ___label="($PROJECT_PATH_NIM_ENGINE)"
        ___location="$(NIM_Get_Activator_Path)"

        if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
                ___brew="eval \$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
                ___brew="eval \$(/usr/local/bin/brew shellenv)"
        else
                ___brew=""
        fi

        FS_Make_Housing_Directory "$___location"
        FS_Write_File "$___location" "\
#!/bin/sh
if [ -z \"\$(type -t 'nim')\" ]; then
        1>&2 printf -- '[ ERROR ] missing nim compiler.\\\\n'
        return 1
fi

if [ -z \"\$(type -t 'nimble')\" ]; then
        1>&2 printf -- '[ ERROR ] missing nimble package manager.\\\\n'
        return 1
fi

deactivate() {
        if [ -z \"\$old_NIMBLE_DIR\" ]; then
                unset old_NIMBLE_DIR NIMBLE_DIR
        else
                NIMBLE_DIR=\"\$old_NIMBLE_DIR\"
                unset old_NIMBLE_DIR
        fi
        export PS1=\"\${PS1##*${___label} }\"
        unset PROJECT_NIM_LOCALIZED
        return 0
}

# check
if [ ! -z \"\$PROJECT_NIM_LOCALIZED\" ]; then
        return 0
fi

# activate
${___brew}
export old_NIMBLE_DIR=\"\$NIMBLE_DIR\"
export NIMBLE_DIR=\"$(FS_Get_Directory "${___location}")\"
export PROJECT_NIM_LOCALIZED='${___location}'
export PS1=\"${___label} \${PS1}\"
return 0
"
        FS_Is_File "${___location}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # testing the activation
        NIM_Activate_Local_Environment
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # report status
        return 0
}
