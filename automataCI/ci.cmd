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
# Scan for fundamental pathing
export PROJECT_PATH_PWD="$PWD"
export PROJECT_PATH_AUTOMATA="automataCI"

if [ -f "./ci.sh" ]; then
        PROJECT_PATH_ROOT="${PWD%/*}/"
else
        __pathing="$PWD"
        __previous=""
        while [ "$__pathing" != "" ]; do
                PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT}${__pathing%%/*}/"
                __pathing="${__pathing#*/}"
                if [ -f "${PROJECT_PATH_ROOT}${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
                        break
                fi

                # stop the scan if the previous pathing is the same as current
                if [ "$__previous" = "$__pathing" ]; then
                        printf "[ ERROR ] unable to detect repo root directory from PWD.\n"
                        exit 1
                        break
                fi
                previous="$__pathing"
        done
        unset __pathing __previous
fi
export PROJECT_PATH_ROOT="${PROJECT_PATH_ROOT%/*}"

# check_executable
if [ ! -f "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/ci.sh" ]; then
        1>&2 printf "[ ERROR ] missing ${PROJECT_PATH_AUTOMATA} directory.\n"
        exit 1
fi

# execute
"${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/ci.sh" "$*"
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

:scan_root_directory
set "PROJECT_PATH_AUTOMATA=automataCI"
set "PROJECT_PATH_PWD=%CD%"
set "PROJECT_PWD=%~dp0."

if exist "%~dp0ci.ps1" (
        for %%a in ("%~dp0..") do set PROJECT_PATH_ROOT=%%~fa
        goto clean_up_root_directory_path
)

for /r "%PROJECT_PWD%" %%d in (.) do (
        set "PROJECT_PATH_ROOT=%%d"

        if exist "!PROJECT_PATH_ROOT!\%PROJECT_PATH_AUTOMATA%\ci.ps1" (
                goto clean_up_root_directory_path
        )

        if "!PROJECT_PATH_ROOT!"=="%~dp0" (
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

:check_executable
if not exist "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\ci.ps1" (
        >&2 echo "[ ERROR ] missing %PROJECT_PATH_AUTOMATA% directory."
        exit /B 1
)

:execute
Powershell.exe ^
        -executionpolicy remotesigned ^
        -File "%PROJECT_PATH_ROOT%\%PROJECT_PATH_AUTOMATA%\ci.ps1" ^
        %*
IF "!ERRORLEVEL!" NEQ "0" (
        EXIT /B 1
)
::##############################################################################
:: Windows Main Codes                                                          #
::##############################################################################
EXIT /B 0
