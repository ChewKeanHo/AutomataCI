#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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

. "${LIBS_AUTOMATACI}/services/io/net/http.sh"
. "${LIBS_AUTOMATACI}/services/ai/google.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# execute
I18N_Activate_Environment
HTTP_Is_Available
if [ $? -ne 0 ]; then
        I18N_Activate_Failed
        return 1
fi


I18N_Run "$PROJECT_GOOGLEAI"
___response="$(GOOGLEAI_Gemini_Query_Text_To_Text "Hi! Are you Gemini?")"


# parse json if available
if [ $(STRINGS_Is_Empty "$___response") -ne 0 ]; then
        OS_Is_Command_Available "jq"
        if [ $? -eq 0 ]; then
                printf -- "%b" "$___response" \
                        | jq --raw-output .candidates[0].content.parts[0].text
        fi
else
        printf -- "%b" "$___response"
fi
I18N_Newline




# report status
return 0
