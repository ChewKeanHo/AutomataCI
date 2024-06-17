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
        >&2 printf "[ ERROR ] - Please run from autoamtaCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# validate input
I18N_Validate_Job
if [ $(STRINGS_Is_Empty "$PROJECT_CI_JOB") -eq 0 ]; then
        I18N_Validate_Failed
        return 1
fi




# execute
Run_Subroutine_Exec() {
        __directory="$1"
        __name="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$__directory") -eq 0 ] ||
                [ "$(STRINGS_To_Uppercase "$__directory")" = "NONE" ]; then
                return 0
        fi

        if [ ! "$(STRINGS_To_Uppercase "$__name")" = "BASELINE" ]; then
                case "$__job" in
                deploy)
                        return 0 # skipped
                        ;;
                *)
                        # accepted
                        ;;
                esac
        fi


        # execute
        ci_job="$(STRINGS_To_Lowercase "${PROJECT_CI_JOB}_unix-any.sh")"
        ci_job="${PROJECT_PATH_ROOT}/${__directory}/${PROJECT_PATH_CI}/${ci_job}"
        FS_Is_File "$ci_job"
        if [ $? -eq 0 ]; then
                I18N_Run "$__name"
                . "$ci_job"
                if [ $? -ne 0 ]; then
                        I18N_Run_Failed
                        return 1
                fi
        fi


        # report status
        return 0
}


Run_Subroutine_Exec "$PROJECT_ANGULAR" "ANGULAR"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_BOOK" "BOOK"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_GO" "GO"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_NIM" "NIM"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_NODE" "NODE"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_PYTHON" "PYTHON"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_RUST" "RUST"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_RESEARCH" "RESEARCH"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_GOOGLEAI" "GOOGLE AI"
if [ $? -ne 0 ]; then
        return 1
fi


Run_Subroutine_Exec "$PROJECT_PATH_SOURCE" "BASELINE"
if [ $? -ne 0 ]; then
        return 1
fi


# IMPORTANT: C can set the terminal into a very strict mode after build causing
#            other technological integrations to fail after run (e.g. flatpak).
#            Therefore, it shall be placed as the last one to execute.
Run_Subroutine_Exec "$PROJECT_C" "C"
if [ $? -ne 0 ]; then
        return 1
fi




# report status
I18N_Run_Successful
return 0
