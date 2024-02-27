# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




function I18N-Param-Process {
	param(
		[string]$___subject
	)


	# execute
	if ($(STRINGS-Is-Empty "${___subject}") -ne 0) {
		return $___subject
	}

	switch ("${env:AUTOMATACI_LANG}") {
	default {
		# fallback to default english
		return "⸨⸨ DEV! MISSING PARAM! ⸩⸩"
	}}


	# report status
	return 0
}
