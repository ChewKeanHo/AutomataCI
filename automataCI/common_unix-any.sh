#!/bin/sh
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




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"

. "${LIBS_AUTOMATACI}/services/i18n/status-run.sh"




# validate input
I18N_Status_Print_Run_CI_Job_Validate
if [ -z "$PROJECT_CI_JOB" ]; then
        I18N_Status_Print_Run_CI_Job_Validate_Failed
        return 1
fi




# execute
RUN_Subroutine_Exec() {
        #__job="$1"
        #__directory="$2"
        #__name="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$2") -eq 0 ] ||
                [ "$(STRINGS::to_uppercase "$2")" = "NONE" ]; then
                return 0
        fi

        if [ ! "$(STRINGS::to_uppercase "$3")" = "BASELINE" ]; then
                case "$1" in
                deploy)
                        return 0 # skipped
                        ;;
                *)
                        ;;
                esac
        fi


        # execute
        ci_job="$(STRINGS::to_lowercase "$1")_unix-any.sh"
        ci_job="${PROJECT_PATH_ROOT}/${2}/${PROJECT_PATH_CI}/${ci_job}"
        FS::is_file "$ci_job"
        if [ $? -eq 0 ]; then
                I18N_Status_Print_Run_CI_Job "$3"
                . "$ci_job"
                if [ $? -ne 0 ]; then
                        I18N_Status_Print_Run_Failed
                        return 1
                fi
        fi


        # report status
        return 0
}


old_IFS="$IFS" printf -- "%s" "\
ANGULAR|${PROJECT_ANGULAR:-none}
C|${PROJECT_C:-none}
GO|${PROJECT_GO:-none}
NIM|${PROJECT_NIM:-none}
PYTHON|${PROJECT_PYTHON:-none}
RUST|${PROJECT_RUST:-none}
BASELINE|${PROJECT_PATH_SOURCE:-none}
" |  while IFS="" read -r __line || [ -n "$__line" ]; do
        RUN_Subroutine_Exec "$PROJECT_CI_JOB" "${__line#*|}" "${__line%|*}"
        if [ $? -ne 0 ]; then
                return 1
        fi
done
___process=$?
IFS="$old_IFS" && unset old_IFS

if [ $___process -ne 0 ]; then
        return 1
fi




# report status
I18N_Status_Print_Run_Successful
return 0
