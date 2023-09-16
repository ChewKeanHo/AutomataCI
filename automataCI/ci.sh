# IMPORTANT NOTE: PLEASE LEAVE THE ABOVE AS IT IS, WHERE IT IS.
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# make sure is by running initialization
if [ ! "$BASH_SOURCE" = "$(command -v $0)" ]; then
        printf "[ ERROR ] - Run me instead! -> $ ./ci.cmd [JOB]\n"
        exit 1
fi




# determine os
PROJECT_OS="$(uname)"
export PROJECT_OS="$(echo "$PROJECT_OS" | tr '[:upper:]' '[:lower:]')"
case "${PROJECT_OS}" in
windows*|ms-dos*)
        export PROJECT_OS='windows'
        ;;
cygwin*|mingw*|mingw32*|msys*)
        export PROJECT_OS='windows' # edge cases. Set it to widnows for now
        ;;
*freebsd)
        export PROJECT_OS='freebsd'
        ;;
dragonfly*)
        export PROJECT_OS='dragonfly'
        ;;
*)
        ;;
esac




# determine arch
PROJECT_ARCH="$(uname -m)"
export PROJECT_ARCH="$(echo "$PROJECT_ARCH" | tr '[:upper:]' '[:lower:]')"
case "${PROJECT_ARCH}" in
i686-64)
        export PROJECT_ARCH='ia64' # Intel Itanium.
        ;;
i386|i486|i586|i686)
        export PROJECT_ARCH='i386'
        ;;
x86_64)
        export PROJECT_ARCH="amd64"
        ;;
sun4u)
        export PROJECT_ARCH='sparc'
        ;;
"power macintosh")
        export PROJECT_ARCH='powerpc'
        ;;
ip*)
        export PROJECT_ARCH='mips'
        ;;
*)
        ;;
esac




# determine PROJECT_PATH_PWD
export PROJECT_PATH_PWD="$PWD"




# scan for PROJECT_PATH_ROOT
__pathing="$PROJECT_PATH_PWD"
__previous=""
while [ "$__pathing" != "" ]; do
        PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT}${__pathing%%/*}/"
        __pathing="${__pathing#*/}"
        if [ -f "${PROJECT_PATH_ROOT}.git/config" ]; then
                break
        fi

        # stop the scan if the previous pathing is the same as current
        if [ "$__previous" = "$__pathing" ]; then
                printf "[ ERROR ] unable to detect repo root directory from PWD.\n"
                exit 1
        fi
        __previous="$__pathing"
done
unset __pathing __previous
export PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT%/*}"
export PROJECT_PATH_AUTOMATA="automataCI"




# parse repo CI configurations
if [ ! -f "${PROJECT_PATH_ROOT}/CONFIG.toml" ]; then
        printf "[ ERROR ] - missing '${PROJECT_PATH_ROOT}/CONFIG.toml' repo config file.\n"
        exit 1
fi
old_IFS="$IFS"
while IFS= read -r line; do
        line="${line%%#*}"
        if [ "$line" = "" ]; then
                continue
        fi

        key="${line%%=*}"
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        key="${key%\"}"
        key="${key#\"}"
        key="${key%\'}"
        key="${key#\'}"

        value="${line##*=}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        export "$key"="$value"
done < "${PROJECT_PATH_ROOT}/CONFIG.toml"




# parse repo CI secret configurations
if [ -f "${PROJECT_PATH_ROOT}/SECRETS.toml" ]; then
        old_IFS="$IFS"
        while IFS= read -r line; do
                line="${line%%#*}"
                if [ "$line" = "" ]; then
                        continue
                fi

                key="${line%%=*}"
                key="${key#"${key%%[![:space:]]*}"}"
                key="${key%"${key##*[![:space:]]}"}"
                key="${key%\"}"
                key="${key#\"}"
                key="${key%\'}"
                key="${key#\'}"

                value="${line##*=}"
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%"${value##*[![:space:]]}"}"
                value="${value%\"}"
                value="${value#\"}"
                value="${value%\'}"
                value="${value#\'}"

                export "$key"="$value"
        done < "${PROJECT_PATH_ROOT}/SECRETS.toml"
fi




# execute command
case "$1" in
env|Env|ENV)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/env_unix-any.sh"
        code=$?
        ;;
setup|Setup|SETUP)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/setup_unix-any.sh"
        code=$?
        ;;
start|Start|START)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/start_unix-any.sh"
        code=$?
        ;;
test|Test|TEST)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/test_unix-any.sh"
        code=$?
        ;;
prepare|Prepare|PREPARE)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/prepare_unix-any.sh"
        code=$?
        ;;
build|Build|BUILD)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/build_unix-any.sh"
        code=$?
        ;;
package|Package|PACKAGE)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/package_unix-any.sh"
        code=$?
        ;;
release|Release|RELEASE)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/release_unix-any.sh"
        code=$?
        ;;
stop|Stop|STOP)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/stop_unix-any.sh"
        code=$?
        unset PROJECT_ARCH PROJECT_OS PROJECT_PATH_PWD PROJECT_PATH_ROOT
        ;;
clean|Clean|CLEAN)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/clean_unix-any.sh"
        code=$?
        ;;
purge|Purge|PURGE)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/purge_unix-any.sh"
        code=$?
        ;;
*)
        case "$1" in
        -h|--help|help|--Help|Help|--HELP|HELP)
                code=0
                ;;
        *)
                printf "[ ERROR ] unknown action.\n"
                code=1
                ;;
        esac
        printf "\nPlease try any of the following:\n"
        printf "        To seek commands' help 🠚        $ ./ci.cmd help\n"
        printf "        To initialize environment 🠚     $ ./ci.cmd env\n"
        printf "        To setup the repo for work 🠚    $ ./ci.cmd setup\n"
        printf "        To start a development 🠚        $ ./ci.cmd start\n"
        printf "        To test the repo 🠚              $ ./ci.cmd test\n"
        printf "        To prepare the repo 🠚           $ ./ci.cmd prepare\n"
        printf "        To build the repo 🠚             $ ./ci.cmd build\n"
        printf "        To package the repo product 🠚   $ ./ci.cmd package\n"
        printf "        To release the repo product 🠚   $ ./ci.cmd release\n"
        printf "        To stop a development 🠚         $ ./ci.cmd stop\n"
        printf "        To clean the workspace 🠚        $ ./ci.cmd clean\n"
        printf "        To purge everything 🠚           $ ./ci.cmd purge\n"
        ;;
esac
exit $code
