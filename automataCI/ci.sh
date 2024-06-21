#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




# determine PROJECT_PATH_PWD
export PROJECT_PATH_PWD="$PWD"
export PROJECT_PATH_AUTOMATA="automataCI"




# determine PROJECT_PATH_ROOT
if [ -f "./ci.sh" ]; then
        PROJECT_PATH_ROOT="${PWD%/*}/"
elif [ -f "./${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
        # current directory is the root directory.
        PROJECT_PATH_ROOT="$PWD"
else
        __pathing="$PROJECT_PATH_PWD"
        __previous=""
        while [ "$__pathing" != "" ]; do
                PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT}${__pathing%%/*}/"
                __pathing="${__pathing#*/}"
                if [ -f "${PROJECT_PATH_ROOT}${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                        break
                fi

                # stop the scan if the previous pathing is the same as current
                if [ "$__previous" = "$__pathing" ]; then
                        1>&2 printf "[ ERROR ] [ ERROR ] Missing root directory.\n"
                        return 1
                fi
                __previous="$__pathing"
        done
        unset __pathing __previous
        export PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT%/*}"

        if [ ! -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                1>&2 printf "[ ERROR ] [ ERROR ] Missing root directory.\n"
                exit 1
        fi
fi

export LIBS_AUTOMATACI="${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}"
export LIBS_HESTIA="${LIBS_AUTOMATACI}/services"




# import fundamental libraries
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# determine host system parameters
export PROJECT_OS="$(OS_Get)"
if [ "$(STRINGS_Is_Empty "$PROJECT_OS")" -eq 0 ]; then
        I18N_Unsupported_OS
        return 1
fi

export PROJECT_ARCH="$(OS_Get_Arch)"
if [ "$(STRINGS_Is_Empty "$PROJECT_ARCH")" -eq 0 ]; then
        I18N_Unsupported_ARCH
        return 1
fi




# parse repo CI configurations
if [ ! -f "${PROJECT_PATH_ROOT}/CONFIG.toml" ]; then
        I18N_Missing "CONFIG.toml"
        return 1
fi


__old_IFS="$IFS"
while IFS= read -r __line || [ -n "$__line" ]; do
        __line="${__line%%#*}"
        if [ "$(STRINGS_Is_Empty "$__line")" -eq 0 ]; then
                continue
        fi

        key="${__line%%=*}"
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        key="${key%\"}"
        key="${key#\"}"
        key="${key%\'}"
        key="${key#\'}"

        value="${__line##*=}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        export "$key"="$value"
done < "${PROJECT_PATH_ROOT}/CONFIG.toml"
IFS="$__old_IFS" && unset __old_IFS




# parse repo CI secret configurations
if [ -f "${PROJECT_PATH_ROOT}/SECRETS.toml" ]; then
        __old_IFS="$IFS"
        while IFS= read -r __line || [ -n "$__line" ]; do
                __line="${__line%%#*}"
                if [ "$(STRINGS_Is_Empty "$__line")" -eq 0 ]; then
                        continue
                fi

                key="${__line%%=*}"
                key="${key#"${key%%[![:space:]]*}"}"
                key="${key%"${key##*[![:space:]]}"}"
                key="${key%\"}"
                key="${key#\"}"
                key="${key%\'}"
                key="${key#\'}"

                value="${__line##*=}"
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%"${value##*[![:space:]]}"}"
                value="${value%\"}"
                value="${value#\"}"
                value="${value%\'}"
                value="${value#\'}"

                export "$key"="$value"
        done < "${PROJECT_PATH_ROOT}/SECRETS.toml"
        IFS="$__old_IFS" && unset __old_IFS
fi




# determine language
export AUTOMATACI_LANG="${AUTOMATACI_LANG:-$(OS_Get_Lang)}"
if [ "$(STRINGS_Is_Empty "$AUTOMATACI_LANG")" -eq 0 ]; then
        export AUTOMATACI_LANG="en" # fall back to english
fi




# update environment variable
OS_Sync




# execute command
case "$1" in
env|Env|ENV)
        export PROJECT_CI_JOB="env"
        . "${LIBS_AUTOMATACI}/env_unix-any.sh"
        __exit_code=$?
        ;;
setup|Setup|SETUP)
        export PROJECT_CI_JOB="setup"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        ;;
start|Start|START)
        export PROJECT_CI_JOB="start"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        ;;
test|Test|TEST)
        export PROJECT_CI_JOB="test"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        ;;
prepare|Prepare|PREPARE)
        export PROJECT_CI_JOB="prepare"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        ;;
materialize|Materialize|MATERIALIZE)
        export PROJECT_CI_JOB="materialize"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        ;;
build|Build|BUILD)
        export PROJECT_CI_JOB="build"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        ;;
notarize|Notarize|NOTARIZE)
        export PROJECT_CI_JOB="notarize"
        . "${LIBS_AUTOMATACI}/notarize_unix-any.sh"
        __exit_code=$?
        ;;
package|Package|PACKAGE)
        export PROJECT_CI_JOB="package"
        . "${LIBS_AUTOMATACI}/package_unix-any.sh"
        __exit_code=$?
        ;;
release|Release|RELEASE)
        export PROJECT_CI_JOB="release"
        . "${LIBS_AUTOMATACI}/release_unix-any.sh"
        __exit_code=$?
        ;;
stop|Stop|STOP)
        export PROJECT_CI_JOB="stop"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        unset PROJECT_ARCH PROJECT_OS PROJECT_PATH_PWD PROJECT_PATH_ROOT
        ;;
deploy|Deploy|DEPLOY)
        export PROJECT_CI_JOB="deploy"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        ;;
archive|Archive|ARCHIVE)
        export PROJECT_CI_JOB="archive"
        . "${LIBS_AUTOMATACI}/archive_unix-any.sh"
        __exit_code=$?
        ;;
clean|Clean|CLEAN)
        export PROJECT_CI_JOB="clean"
        . "${LIBS_AUTOMATACI}/common_unix-any.sh"
        __exit_code=$?
        ;;
purge|Purge|PURGE)
        export PROJECT_CI_JOB="purge"
        . "${LIBS_AUTOMATACI}/purge_unix-any.sh"
        __exit_code=$?
        ;;
*)
        case "$1" in
        -h|--help|help|--Help|Help|--HELP|HELP)
                I18N_Help info
                __exit_code=0
                ;;
        *)
                I18N_Unknown_Action
                I18N_Help note
                __exit_code=1
                ;;
        esac
        ;;
esac
return $__exit_code
