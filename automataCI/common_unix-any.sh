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
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
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
technologies="\
ANGULAR|${PROJECT_ANGULAR:-none}
C|${PROJECT_C:-none}
GO|${PROJECT_GO:-none}
NIM|${PROJECT_NIM:-none}
PYTHON|${PROJECT_PYTHON:-none}
RUST|${PROJECT_RUST:-none}
BASELINE|${PROJECT_PATH_SOURCE:-none}
"

old_IFS="$IFS"
while IFS= read -r tech || [ -n "$tech" ]; do
        if [ $(STRINGS_Is_Empty "${tech#*|}") -eq 0 ] ||
                [ "$(STRINGS::to_uppercase "${tech#*|}")" = "NONE" ]; then
                continue
        fi

        if [ ! "$(STRINGS::to_uppercase "${tech%|*}")" = "BASELINE" ]; then
                case "$1" in
                deploy)
                        continue # skipped
                        ;;
                *)
                        ;;
                esac
        fi


        # execute
        ci_job="$(STRINGS::to_lowercase "${PROJECT_CI_JOB}")_unix-any.sh"
        ci_job="${PROJECT_PATH_ROOT}/${tech#*|}/${PROJECT_PATH_CI}/${ci_job}"
        FS::is_file "$ci_job"
        if [ $? -eq 0 ]; then
                I18N_Run "${tech%|*}"
                . "$ci_job"
                if [ $? -ne 0 ]; then
                        I18N_Run_Failed
                        continue
                fi
        fi
done <<EOF
$technologies
EOF
IFS="$old_IFS" && unset old_IFS




# report status
I18N_Run_Successful
return 0
