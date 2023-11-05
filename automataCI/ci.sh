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




# detects initializer
if [ ! -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/init.sh" ]; then
        printf "[ ERROR ] unable to find initializer service script.\n"
        exit 1
fi
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/init.sh"
if [ $? -ne 0 ]; then
        printf "[ ERROR ] initialization failed.\n"
        exit 1
fi




# execute command
case "$1" in
env|Env|ENV)
        export PROJECT_CI_JOB="env"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/env_unix-any.sh"
        code=$?
        ;;
setup|Setup|SETUP)
        export PROJECT_CI_JOB="setup"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        ;;
start|Start|START)
        export PROJECT_CI_JOB="start"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        ;;
test|Test|TEST)
        export PROJECT_CI_JOB="test"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        ;;
prepare|Prepare|PREPARE)
        export PROJECT_CI_JOB="prepare"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        ;;
materialize|Materialize|MATERIALIZE)
        export PROJECT_CI_JOB="materialize"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        ;;
build|Build|BUILD)
        export PROJECT_CI_JOB="build"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        ;;
notarize|Notarize|NOTARIZE)
        export PROJECT_CI_JOB="notarize"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/notarize_unix-any.sh"
        code=$?
        ;;
package|Package|PACKAGE)
        export PROJECT_CI_JOB="package"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/package_unix-any.sh"
        code=$?
        ;;
release|Release|RELEASE)
        export PROJECT_CI_JOB="release"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/release_unix-any.sh"
        code=$?
        ;;
stop|Stop|STOP)
        export PROJECT_CI_JOB="stop"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        unset PROJECT_ARCH PROJECT_OS PROJECT_PATH_PWD PROJECT_PATH_ROOT
        ;;
deploy|Deploy|DEPLOY)
        export PROJECT_CI_JOB="deploy"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        ;;
clean|Clean|CLEAN)
        export PROJECT_CI_JOB="clean"
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/common_unix-any.sh"
        code=$?
        ;;
purge|Purge|PURGE)
        export PROJECT_CI_JOB="purge"
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
        printf "        To prepare the repo 🠚           $ ./ci.cmd prepare\n"
        printf "        To start a development 🠚        $ ./ci.cmd start\n"
        printf "        To test the repo 🠚              $ ./ci.cmd test\n"
        printf "        Like build but only for host 🠚  $ ./ci.cmd materialize\n"
        printf "        To build the repo 🠚             $ ./ci.cmd build\n"
        printf "        To notarize the builds 🠚        $ ./ci.cmd notarize\n"
        printf "        To package the repo product 🠚   $ ./ci.cmd package\n"
        printf "        To release the repo product 🠚   $ ./ci.cmd release\n"
        printf "        To stop a development 🠚         $ ./ci.cmd stop\n"
        printf "        To deploy the new release 🠚     $ ./ci.cmd deploy\n"
        printf "        To clean the workspace 🠚        $ ./ci.cmd clean\n"
        printf "        To purge everything 🠚           $ ./ci.cmd purge\n"
        ;;
esac
exit $code
