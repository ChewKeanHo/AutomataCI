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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/strings.sh"




NIM::activate_local_environment() {
        # validate input
        NIM::is_available
        if [ $? -ne 0 ] ; then
                return 1
        fi

        NIM::is_localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        __location="$(NIM::get_activator_path)"
        if [ ! -f "$__location" ]; then
                return 1
        fi

        . "$__location"
        NIM::is_localized
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




NIM::check_package() {
        #__directory="$1"


        # execute
        __current_path="$PWD" && cd "$1"
        nimble check
        __exit=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




NIM::get_activator_path() {
        # execute
        __location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_NIM_ENGINE}"
        __location="${__location}/activate.sh"
        printf -- "%b" "$__location"


        # report status
        return 0
}




NIM::is_available() {
        # execute
        if [ -z "$(type -t nim)" ]; then
                return 1
        fi

        if [ -z "$(type -t nimble)" ]; then
                return 1
        fi

        if [ -z "$(type -t gcc)" ] && [ -z "$(type -t clang)" ]; then
                return 1
        fi


        # report status
        return 0
}




NIM::is_localized() {
        # execute
        if [ ! -z "$PROJECT_NIM_LOCALIZED" ] ; then
                return 0
        fi


        # report status
        return 1
}




NIM::setup_local_environment() {
        # validate input
        if [ -z "$PROJECT_PATH_ROOT" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_TOOLS" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_NIM_ENGINE" ]; then
                return 1
        fi


        # execute
        NIM::is_available
        if [ $? -ne 0 ] ; then
                return 1
        fi

        NIM::is_localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        ## it's a clean repo. Start setting up localized environment...
        __label="($PROJECT_PATH_NIM_ENGINE)"
        __location="$(NIM::get_activator_path)"

        if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
                __brew="eval \$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
                __brew="eval \$(/usr/local/bin/brew shellenv)"
        else
                __brew=""
        fi

        FS_Make_Housing_Directory "$__location"
        FS_Write_File "${__location}" "\
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
        export PS1=\"\${PS1##*${__label} }\"
        unset PROJECT_NIM_LOCALIZED
        return 0
}

# activate
${__brew}
export old_NIMBLE_DIR=\"\$NIMBLE_DIR\"
export NIMBLE_DIR=\"${__location%/*}\"
export PROJECT_NIM_LOCALIZED='${__location}'
export PS1=\"${__label} \${PS1}\"
return 0
"
        if [ ! -f "${__location}" ]; then
                return 1
        fi


        # testing the activation
        . "${__location}"
        if [ $? -ne 0 ] ; then
                return 1
        fi


        # report status
        return 0
}
