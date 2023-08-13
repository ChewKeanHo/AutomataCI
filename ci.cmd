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
if [ "$BASH_SOURCE" = "$(command -v $0)" ]; then
        printf "[ ERROR ] - Source me instead! -> $ . ./start.cmd\n"
        exit 1
fi
code=0




# (2) determine os
PROJECT_OS="$(uname)"
export PROJECT_OS="$(echo "$PROJECT_OS" | tr '[:upper:]' '[:lower:]')"
case "${PROJECT_OS}" in
windows*|ms-dos*)
        export EDM_OS='windows'
        ;;
cygwin*|mingw*|mingw32*|msys*)
        export EDM_OS='windows' # edge cases. Set it to widnows for now
        ;;
*freebsd)
        export EDM_OS='freebsd'
        ;;
dragonfly*)
        export EDM_OS='dragonfly'
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
        export EDM_ARCH='ia64' # Intel Itanium.
        ;;
i386|i486|i586|i686)
        export EDM_ARCH='i386'
        ;;
x86_64)
        export PROJECT_ARCH="amd64"
        ;;
sun4u)
        export EDM_ARCH='sparc'
        ;;
"power macintosh")
        export EDM_ARCH='powerpc'
        ;;
ip*)
        export EDM_ARCH='mips'
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
        if [ -f "${PROJECT_PATH_ROOT}/.git/config" ]; then
                break
        fi

        # stop the scan if the previous pathing is the same as current
        if [ "$previous" = "$pathing" ]; then
                printf "[ ERROR ] unable to detect repo root directory from PWD.\n"
                return 1
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
        return 1
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
        stop|Stop|STOP)
                unset "$key"
                ;;
        start|Start|START)
                export "$key"="$value"
                ;;
        test|Test|TEST)
                export "$key"="$value"
                ;;
        prepare|Prepare|PREPARE)
                export "$key"="$value"
                ;;
        build|Build|BUILD)
                export "$key"="$value"
                ;;
        package|Package|PACKAGE)
                export "$key"="$value"
                ;;
        release|Release|RELEASE)
                export "$key"="$value"
                ;;
        compose|Compose|COMPOSE)
                export "$key"="$value"
                ;;
        publish|Publish|PUBLISH)
                export "$key"="$value"
                ;;
        *)
                ;;
        esac
done < "${PROJECT_PATH_ROOT}/CONFIG.toml"




# (5) execute command
case "$1" in
setup|Setup|SETUP)
        . "${PROJECT_PATH_ROOT}"/automata/setup_unix-any.sh
        code=$?
        ;;
start|Start|START)
        . "${PROJECT_PATH_ROOT}"/automata/start_unix-any.sh
        code=$?
        ;;
test|Test|TEST)
        . "${PROJECT_PATH_ROOT}"/automata/test_unix-any.sh
        code=$?
        ;;
prepare|Prepare|PREPARE)
        . "${PROJECT_PATH_ROOT}"/automata/prepare_unix-any.sh
        code=$?
        ;;
build|Build|BUILD)
        . "${PROJECT_PATH_ROOT}"/automata/build_unix-any.sh
        code=$?
        ;;
package|Package|PACKAGE)
        . "${PROJECT_PATH_ROOT}"/automata/package_unix-any.sh
        code=$?
        ;;
release|Release|RELEASE)
        . "${PROJECT_PATH_ROOT}"/automata/release_unix-any.sh
        code=$?
        ;;
compose|Compose|COMPOSE)
        . "${PROJECT_PATH_ROOT}"/automata/compose_unix-any.sh
        code=$?
        ;;
publish|Publish|PUBLISH)
        . "${PROJECT_PATH_ROOT}"/automata/publish_unix-any.sh
        code=$?
        ;;
stop|Stop|STOP)
        . "${PROJECT_PATH_ROOT}"/automata/stop_unix-any.sh
        code=$?
        unset PROJECT_ARCH PROJECT_OS PROJECT_PATH_PWD PROJECT_PATH_ROOT
        ;;
*)
        printf "[ ERROR ] unknown action. Please try any of the following:\n"
        printf "        To setup the repo for work 🠚    $ . ci.cmd setup\n"
        printf "        To start a development 🠚        $ . ci.cmd start\n"
        printf "        To test the repo 🠚              $ . ci.cmd test\n"
        printf "        To prepare the repo 🠚           $ . ci.cmd prepare\n"
        printf "        To build the repo 🠚             $ . ci.cmd build\n"
        printf "        To package the repo product 🠚   $ . ci.cmd package\n"
        printf "        To release the repo product 🠚   $ . ci.cmd release\n"
        printf "        To compose the documents 🠚      $ . ci.cmd compose\n"
        printf "        To publish the documents 🠚      $ . ci.cmd publish\n"
        printf "        To stop a development 🠚         $ . ci.cmd stop\n"
        code=1
        unset PROJECT_ARCH PROJECT_OS PROJECT_PATH_PWD PROJECT_PATH_ROOT
        ;;
esac
################################################################################
# Unix Main Codes                                                              #
################################################################################
return $code




:WINDOWS
::##############################################################################
:: Windows Main Codes                                                          #
::##############################################################################
@echo off
setlocal enabledelayedexpansion
set code=0

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
        echo "NOTE: GitHub Action Windows Server detected. Simulating amd64 CPU."
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
        set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        set code=1
        goto :print_help
)

IF "%1"=="setup" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\automata\setup_windows-any.ps1"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Setup" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\automata\setup_windows-any.ps1"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="SETUP" (
        Powershell.exe ^
                -executionpolicy remotesigned ^
                -File "%PROJECT_PATH_ROOT%\automata\setup_windows-any.ps1"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="start" (
        call "%PROJECT_PATH_ROOT%\automata\start_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Start" (
        call "%PROJECT_PATH_ROOT%\automata\start_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="START" (
        call "%PROJECT_PATH_ROOT\automata\start_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="test" (
        call "%PROJECT_PATH_ROOT%\automata\test_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Test" (
        call "%PROJECT_PATH_ROOT%\automata\test_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="TEST" (
        call "%PROJECT_PATH_ROOT%\automata\TEST_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="prepare" (
        call "%PROJECT_PATH_ROOT%\automata\prepare_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Prepare" (
        call "%PROJECT_PATH_ROOT%\automata\prepare_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="PREPARE" (
        call "%PROJECT_PATH_ROOT%\automata\prepare_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="build" (
        call "%PROJECT_PATH_ROOT%\automata\build_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Build" (
        call "%PROJECT_PATH_ROOT%\automata\build_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="BUILD" (
        call "%PROJECT_PATH_ROOT%\automata\build_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="package" (
        call "%PROJECT_PATH_ROOT%\automata\package_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Package" (
        call "%PROJECT_PATH_ROOT%\automata\package_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="PACKAGE" (
        call "%PROJECT_PATH_ROOT%\automata\package_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="release" (
        call "%PROJECT_PATH_ROOT%\automata\release_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Release" (
        call "%PROJECT_PATH_ROOT%\automata\release_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="RELEASE" (
        call "%PROJECT_PATH_ROOT%\automata\release_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="compose" (
        call "%PROJECT_PATH_ROOT%\automata\compose_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Compose" (
        call "%PROJECT_PATH_ROOT%\automata\compose_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="COMPOSE" (
        call "%PROJECT_PATH_ROOT%\automata\compose_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="publish" (
        call "%PROJECT_PATH_ROOT%\automata\publish_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="Publish" (
        call "%PROJECT_PATH_ROOT%\automata\publish_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="PUBLISH" (
        call "%PROJECT_PATH_ROOT%\automata\publish_windows-any.cmd"
        set code="%ERRORLEVEL%"
        goto :end
) ELSE IF "%1"=="stop" (
        call "%PROJECT_PATH_ROOT%\automata\stop_windows-any.cmd"
        set code="%ERRORLEVEL%"
        set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        goto :end
) ELSE IF "%1"=="Stop" (
        call "%PROJECT_PATH_ROOT%\automata\stop_windows-any.cmd"
        set code="%ERRORLEVEL%"
        set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        goto :end
) ELSE IF "%1"=="STOP" (
        call "%PROJECT_PATH_ROOT%\automata\stop_windows-any.cmd"
        set code="%ERRORLEVEL%"
        set PROJECT_ARCH= PROJECT_OS= PROJECT_PATH_PWD= PROJECT_PATH_ROOT=
        goto :end
) ELSE (
        set code=1
        goto :print_help
)

:print_help
        echo "[ ERROR ] unknown action. Please try any of the following:\n"
        echo "        To setup the repo for work 🠚    $ . ci.cmd setup\n"
        echo "        To start a development 🠚        $ . ci.cmd start\n"
        echo "        To test the repo 🠚              $ . ci.cmd test\n"
        echo "        To prepare the repo 🠚           $ . ci.cmd prepare\n"
        echo "        To build the repo 🠚             $ . ci.cmd build\n"
        echo "        To package the repo product 🠚   $ . ci.cmd package\n"
        echo "        To release the repo product 🠚   $ . ci.cmd release\n"
        echo "        To compose the documents 🠚      $ . ci.cmd compose\n"
        echo "        To publish the documents 🠚      $ . ci.cmd publish\n"
        echo "        To stop a development 🠚         $ . ci.cmd stop\n"

:end
::##############################################################################
:: Windows Main Codes                                                          #
::##############################################################################
EXIT /B %code%
