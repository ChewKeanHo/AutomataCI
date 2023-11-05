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
        if [ -f "${PROJECT_PATH_ROOT}automataCI/ci.sh" ]; then
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




# update environment variables
case "$PROJECT_OS" in
linux)
        __location="/home/linuxbrew/.linuxbrew/bin/brew"
        ;;
darwin)
        __location="/usr/local/bin/brew"
        ;;
*)
        ;;
esac
if [ -f "$__location" ]; then
        eval "$("${__location}" shellenv)"
fi




# report status
return 0
