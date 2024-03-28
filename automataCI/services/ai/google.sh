#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/net/http.sh"




GOOGLEAI_Gemini_Query_Text_To_Text() {
        #___query="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        GOOGLEAI_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi


        # configure
        if [ $(STRINGS_Is_Empty "$GOOGLEAI_BLOCK_HATE_SPEECH") -eq 0 ]; then
                GOOGLEAI_BLOCK_HATE_SPEECH="BLOCK_NONE"
        fi

        if [ $(STRINGS_Is_Empty "$GOOGLEAI_BLOCK_SEXUALLY_EXPLICIT") -eq 0 ]; then
                GOOGLEAI_BLOCK_SEXUALLY_EXPLICIT="BLOCK_NONE"
        fi

        if [ $(STRINGS_Is_Empty "$GOOGLEAI_BLOCK_DANGEROUS_CONTENT") -eq 0 ]; then
                GOOGLEAI_BLOCK_DANGEROUS_CONTENT="BLOCK_NONE"
        fi

        if [ $(STRINGS_Is_Empty "$GOOGLEAI_BLOCK_HARASSMENT") -eq 0 ]; then
                GOOGLEAI_BLOCK_HARASSMENT="BLOCK_NONE"
        fi

        ___url="${GOOGLEAI_API_URL}/${GOOGLEAI_API_VERSION}/${GOOGLEAI_MODEL}"
        ___url="${___url}:generateContent?key=${GOOGLEAI_API_TOKEN}"


        # execute
        curl --progress-bar --header 'Content-Type: application/json' --data "{
        \"contents\": [{
                \"parts\":[{
                        \"text\": \"${1}\"
                }],
                \"role\": \"user\"
        }],
        \"safetySettings\": [{
                \"category\": \"HARM_CATEGORY_HATE_SPEECH\",
                \"threshold\": \"${GOOGLEAI_BLOCK_HATE_SPEECH}\"
        },  {
                \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",
                \"threshold\": \"${GOOGLEAI_BLOCK_SEXUALLY_EXPLICIT}\"
        },  {
                \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",
                \"threshold\": \"${GOOGLEAI_BLOCK_DANGEROUS_CONTENT}\"
        },  {
                \"category\": \"HARM_CATEGORY_HARASSMENT\",
                \"threshold\": \"${GOOGLEAI_BLOCK_HARASSMENT}\"
        }]
}" --request POST "$___url"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




GOOGLEAI_Is_Available() {
        # execute
        HTTP_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$GOOGLEAI_API_URL") -eq 0 ] &&
                [ $(STRINGS_Is_Empty "$GOOGLEAI_API_VERSION") -eq 0 ] &&
                [ $(STRINGS_Is_Empty "$GOOGLEAI_MODEL") -eq 0 ] &&
                [ $(STRINGS_Is_Empty "$GOOGLEAI_API_TOKEN") -eq 0 ] &&
                [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi


        # report status
        return 0
}
