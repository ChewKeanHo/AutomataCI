# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function GOOGLEAI-Gemini-Query-Text-To-Text() {
	param(
		[string]$___query
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___query}") -eq 0) {
		return 1
	}

	$___process = GOOGLEAI-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# configure
	if ($(STRINGS-Is-Empty "${env:GOOGLEAI_BLOCK_HATE_SPEECH}") -eq 0) {
		${env:GOOGLEAI_BLOCK_HATE_SPEECH} = "BLOCK_NONE"
	}

	if ($(STRINGS-Is-Empty "${GOOGLEAI_BLOCK_SEXUALLY_EXPLICIT}") -eq 0) {
		${GOOGLEAI_BLOCK_SEXUALLY_EXPLICIT} = "BLOCK_NONE"
	}

	if ($(STRINGS-Is-Empty "${GOOGLEAI_BLOCK_DANGEROUS_CONTENT}") -eq 0) {
		${GOOGLEAI_BLOCK_DANGEROUS_CONTENT} = "BLOCK_NONE"
	}

	if ($(STRINGS-Is-Empty "${env:GOOGLEAI_BLOCK_HARASSMENT}") -eq 0) {
		${env:GOOGLEAI_BLOCK_HARASSMENT} = "BLOCK_NONE"
	}

	$___url = "${env:GOOGLEAI_API_URL}/${env:GOOGLEAI_API_VERSION}/${env:GOOGLEAI_MODEL}"
	$___url = "${___url}:generateContent?key=${env:GOOGLEAI_API_TOKEN}"


	# execute
	return "$(curl.exe --progress-bar --header 'Content-Type: application/json' --data @"
{
	"contents" = [{
		"parts": [{
			"text": "${___query}"
		}],
		"role": "user"
	}],
	"safetySettings": [{
		"category": "HARM_CATEGORY_HATE_SPEECH",
		"threshold": "${env:GOOGLEAI_BLOCK_HATE_SPEECH}"
	}, {
		"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
		"threshold": "${env:GOOGLEAI_BLOCK_SEXUALLY_EXPLICIT}"
	}, {
		"category": "HARM_CATEGORY_DANGEROUS_CONTENT",
		"threshold": "${env:GOOGLEAI_BLOCK_DANGEROUS_CONTENT}"
	}, {
		"category": "HARM_CATEGORY_HARASSMENT",
		"threshold": "${env:GOOGLEAI_BLOCK_HARASSMENT}"
	}]
}
"@ `
	--request POST "$___url")"
}




function GOOGLEAI-Is-Available {
	# report status
	return 0
}
