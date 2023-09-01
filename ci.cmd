echo >/dev/null # >nul & GOTO WINDOWS & rem ^
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
################################################################################
# Unix Main Codes                                                              #
################################################################################
# (1) make sure is by sourcing initialization
if [ ! "$BASH_SOURCE" = "$(command -v $0)" ]; then
        printf "[ ERROR ] - Run me instead! -> $ ./ci.cmd [JOB]\n"
        return 1
fi
code=0




# (2) determine os
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
x86_64)
        export PROJECT_OS="amd64"
        ;;
*)
        ;;
esac




# (3) determine arch
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




# (4) determine critical directories
export PROJECT_PATH_PWD="$PWD"
PROJECT_PATH_ROOT=""


# (4.1) Scan for pathing
pathing="$PROJECT_PATH_PWD"
previous=""
while [ "$pathing" != "" ]; do
        PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT}${pathing%%/*}/"
        pathing="${pathing#*/}"
        if [ -f "${PROJECT_PATH_ROOT}.git/config" ]; then
                break
        fi

        # stop the scan if the previous pathing is the same as current
        if [ "$previous" = "$pathing" ]; then
                printf "[ ERROR ] unable to detect repo root directory from PWD.\n"
                exit 1
                break
        fi
        previous="$pathing"
done
unset pathing previous
PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT%/*}"
export PROJECT_PATH_ROOT




# (3) parse repo CI configurations
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

        case "$1" in
        stop|--stop|Stop|--Stop|STOP|--STOP)
                if [ "$key" = "PROJECT_PATH_AUTOMATA" ]; then
                        export "$key"="$value"
                        continue
                fi
                unset "$key"
                ;;
        *)
                export "$key"="$value"
                ;;
        esac
done < "${PROJECT_PATH_ROOT}/CONFIG.toml"




# (5) execute command
case "$1" in
env|--env|Env|--Env|ENV|--ENV)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/env_unix-any.sh"
        code=$?
        ;;
setup|--setup|Setup|--Setup|SETUP|--SETUP)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/setup_unix-any.sh"
        code=$?
        ;;
start|--start|Start|--Start|START|--START)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/start_unix-any.sh"
        code=$?
        ;;
test|--test|Test|--Test|TEST|--TEST)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/test_unix-any.sh"
        code=$?
        ;;
prepare|--prepare|Prepare|--Prepare|PREPARE|--PREPARE)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/prepare_unix-any.sh"
        code=$?
        ;;
build|--build|Build|--Build|BUILD|--BUILD)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/build_unix-any.sh"
        code=$?
        ;;
package|--package|Package|--Package|PACKAGE|--PACKAGE)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/package_unix-any.sh"
        code=$?
        ;;
release|--release|Release|--Release|RELEASE|--RELEASE)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/release_unix-any.sh"
        code=$?
        ;;
compose|--compose|Compose|--Compose|COMPOSE|--COMPOSE)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/compose_unix-any.sh"
        code=$?
        ;;
publish|--publish|Publish|--Publish|PUBLISH|--PUBLISH)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/publish_unix-any.sh"
        code=$?
        ;;
stop|--stop|Stop|--Stop|STOP|--STOP)
        . "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/stop_unix-any.sh"
        code=$?
        unset PROJECT_ARCH PROJECT_OS PROJECT_PATH_PWD PROJECT_PATH_ROOT
        ;;
*)
        case "$1" in
        -h|--help|help|--Help|Help|--HELP|HELP)
                code=1
                ;;
        *)
                printf "[ ERROR ] unknown action.\n"
                code=1
                ;;
        esac
        echo "Please try any of the following:\n"
        printf "        To seek commands' help 🠚        $ ./ci.cmd help\n"
        printf "        To initialize environment 🠚     $ ./ci.cmd env\n"
        printf "        To setup the repo for work 🠚    $ ./ci.cmd setup\n"
        printf "        To start a development 🠚        $ ./ci.cmd start\n"
        printf "        To test the repo 🠚              $ ./ci.cmd test\n"
        printf "        To prepare the repo 🠚           $ ./ci.cmd prepare\n"
        printf "        To build the repo 🠚             $ ./ci.cmd build\n"
        printf "        To package the repo product 🠚   $ ./ci.cmd package\n"
        printf "        To release the repo product 🠚   $ ./ci.cmd release\n"
        printf "        To compose the documents 🠚      $ ./ci.cmd compose\n"
        printf "        To publish the documents 🠚      $ ./ci.cmd publish\n"
        printf "        To stop a development 🠚         $ ./ci.cmd stop\n"
        ;;
esac
################################################################################
# Unix Main Codes                                                              #
################################################################################
exit $code




:WINDOWS
::##############################################################################
:: Windows Main Codes                                                          #
::##############################################################################
@echo off
setlocal enabledelayedexpansion
set "code=0"

:query_architecture
for /F "skip=1 delims=" %%A in ('wmic cpu get architecture') do (
        set "PROJECT_ARCH=%%A"
        goto :check_architecture
)

:check_architecture
set "PROJECT_ARCH=!PROJECT_ARCH:~0,-1!"
set "PROJECT_ARCH=!PROJECT_ARCH: =!"
IF "!PROJECT_ARCH!"=="x86" (
        set "PROJECT_ARCH=i386"
        goto check_type
) ELSE IF "!PROJECT_ARCH!"=="9" (
        echo [ NOTE ] GitHub Action Windows Server detected. Simulating amd64 CPU.
        set "PROJECT_ARCH=amd64"
) ELSE IF "!PROJECT_ARCH!"=="64" (
        for /F "skip=1 delims=" %%P in ('wmic cpu get name') do (
                set "PROJECT_ARCH=%%P"
                goto check_type
        )
) ELSE (
        echo "[ ERROR ] Unsupported architecture: !PROJECT_ARCH!"
        set code=1
        goto: end
)

:check_type
IF "!PROJECT_ARCH:~0,4!"=="ARM " (
        set "PROJECT_ARCH=arm64"
) ELSE (
        set "PROJECT_ARCH=amd64"
)

:set_os
set "PROJECT_OS=windows"

:scan_root_directory
set "PROJECT_PWD=%CD%"
for /r "%PROJECT_PWD%" %%d in (.) do (
        set "PROJECT_PATH_ROOT=%%d"
        if exist "!PROJECT_PATH_ROOT!\.git\config" (
                goto clean_up_root_directory_path
        )

        if "!PROJECT_PATH_ROOT!"=="%CD%" (
                echo "[ ERROR ] unable to detect repo root directory from PWD.\n"
                set code=1
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
                goto end
        )
)

:clean_up_root_directory_path
if "%PROJECT_PATH_ROOT:~-1%"=="." (
        set "PROJECT_PATH_ROOT=%PROJECT_PATH_ROOT:~0,-1%"
)
if "%PROJECT_PATH_ROOT:~-1%"=="\" (
        set "PROJECT_PATH_ROOT=%PROJECT_PATH_ROOT:~0,-1%"
)

:parse_config_file
if not exist "%PROJECT_PATH_ROOT%\CONFIG.toml" (
        echo "[ ERROR ] unable to locate CONFIG.toml file.\n"
        set code=1
        set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        goto end
)

for /F "usebackq delims=" %%A in ("%PROJECT_PATH_ROOT%\CONFIG.toml") do (
        set "subject=%%A"
        set "line="
        if not "!subject:~0,1!"=="#" (
                for /F "tokens=1,2 delims=#" %%a in ("!subject!") do (
                        if NOT "!stop!"=="1" (
                                set "line=!line!%%a"
                        )
                )
        )

        if not [!line!] == [] (
                set "key="
                set "value="

                for /F "tokens=1,2 delims==" %%a in ("!line!") do (
                        set "key=%%a"
                        set "value=%%b"

                        set "key=!key: =!"
                        set "key=!key:	=!"
                        set "key=!key:"=!"
                        set "key=!key:'=!"

                        set "value=!value: =!"
                        set "value=!value:	=!"
                        set "value=!value:"=!"
                        set "value=!value:'=!"
                )

                set "!key!=!value!"
        )
)

:start_job
IF "%1"=="" (
        echo "[ ERROR ] missing action.\n"
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=1
        goto :print_help
)

IF "%1"=="env" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\env_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Env" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\env_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="ENV" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\env_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="setup" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\setup_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Setup" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\setup_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="SETUP" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\setup_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="start" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\start_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Start" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\start_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="START" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\start_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="test" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\test_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Test" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\test_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="TEST" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\test_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="prepare" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\prepare_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Prepare" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\prepare_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="PREPARE" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\prepare_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="build" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\build_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Build" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\build_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="BUILD" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\build_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="package" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\package_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Package" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\package_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="PACKAGE" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\package_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="release" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\release_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Release" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\release_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="RELEASE" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\release_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="compose" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\compose_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Compose" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\compose_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="COMPOSE" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\compose_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="publish" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\publish_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="Publish" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\publish_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="PUBLISH" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\publish_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        goto end
) ELSE IF "%1"=="stop" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\stop_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        goto end
) ELSE IF "%1"=="Stop" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\stop_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        goto end
) ELSE IF "%1"=="STOP" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\stop_windows-any.ps1"
        IF "!ERRORLEVEL!" NEQ "0" (
                set code=1
        )
        set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        goto end
) ELSE IF "%1"=="-h" (
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=0
        goto print_help
) ELSE IF "%1"=="--help" (
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=0
        goto print_help
) ELSE IF "%1"=="--Help" (
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=0
        goto print_help
) ELSE IF "%1"=="--HELP" (
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=0
        goto print_help
) ELSE IF "%1"=="help" (
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=0
        goto print_help
) ELSE IF "%1"=="Help" (
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=0
        goto print_help
) ELSE IF "%1"=="HELP" (
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=0
        goto print_help
) ELSE (
        echo "[ ERROR ] Unknown action '%1'.\n"
        if not "!was_set!" == "1" (
                set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        )
        set code=1
        goto print_help
)

:print_help
        echo "Please try any of the following:\n"
        echo "        To seek commands' help 🠚        $ .\ci.cmd help\n"
        echo "        To initialize environment 🠚     $ .\ci.cmd env\n"
        echo "        To setup the repo for work 🠚    $ .\ci.cmd setup\n"
        echo "        To start a development 🠚        $ .\ci.cmd start\n"
        echo "        To test the repo 🠚              $ .\ci.cmd test\n"
        echo "        To prepare the repo 🠚           $ .\ci.cmd prepare\n"
        echo "        To build the repo 🠚             $ .\ci.cmd build\n"
        echo "        To package the repo product 🠚   $ .\ci.cmd package\n"
        echo "        To release the repo product 🠚   $ .\ci.cmd release\n"
        echo "        To compose the documents 🠚      $ .\ci.cmd compose\n"
        echo "        To publish the documents 🠚      $ .\ci.cmd publish\n"
        echo "        To stop a development 🠚         $ .\ci.cmd stop\n"

:end
::##############################################################################
:: Windows Main Codes                                                          #
::##############################################################################
EXIT /B %code%
