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




GO::activate_local_environment() {
        # validate input
        GO::is_available
        if [ $? -ne 0 ] ; then
                return 1
        fi

        GO::is_localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        # execute
        __location="$(GO::get_activator_path)"
        if [ ! -f "$__location" ]; then
                return 1
        fi

        . "$__location"
        GO::is_localized
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}




GO::get_activator_path() {
        __location="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TOOLS}/${PROJECT_PATH_GO_ENGINE}"
        __location="${__location}/activate.sh"
        printf -- "%b" "$__location"
}




GO::is_available() {
        if [ ! -z "$(type -t go)" ]; then
                return 0
        fi

        return 1
}




GO::is_localized() {
        if [ ! -z "$PROJECT_GO_LOCALIZED" ] ; then
                return 0
        fi

        return 1
}




GO::setup_local_environment() {
        # validate input
        if [ -z "$PROJECT_PATH_ROOT" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_TOOLS" ]; then
                return 1
        fi

        if [ -z "$PROJECT_PATH_GO_ENGINE" ]; then
                return 1
        fi


        # execute
        GO::is_available
        if [ $? -ne 0 ] ; then
                return 1
        fi

        GO::is_localized
        if [ $? -eq 0 ] ; then
                return 0
        fi


        ## it's a clean repo. Start setting up localized environment...
        __label="($PROJECT_PATH_GO_ENGINE)"
        __location="$(GO::get_activator_path)"

        FS::make_housing_directory "$__location"
        FS::make_directory "${__location%/*}/bin"
        FS::make_directory "${__location%/*}/cache"
        FS::make_directory "${__location%/*}/env"
        FS::write_file "${__location}" "\
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
        export PS1=\"\${PS1##*${__label} }\"
        unset PROJECT_GO_LOCALIZED
        return 0
}

# activate
export GOPATH='${__location%/*}'
export GOBIN='${__location%/*}/bin'
export GOCACHE='${__location%/*}/cache'
export GOENV='${__location%/*}/env'
export PROJECT_GO_LOCALIZED='${__location}'
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
