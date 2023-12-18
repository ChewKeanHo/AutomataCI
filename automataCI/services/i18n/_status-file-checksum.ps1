# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:LIBS_AUTOMATACI}\services\i18n\printer.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function I18N-Status-Print-File-Checksum {
	param(
		[string]$___subject,
		[string]$___algo
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"

		if ($(STRINGS-Is-Empty "${___algo}") -ne 0) {
			$null = I18N-Status-Print info "${___algo} checksum-ing ${___subject}`n"
		} else {
			$null = I18N-Status-Print info "checksum-ing ${___subject}`n"
		}
	}}


	# report status
	return 0
}




function I18N-Status-Print-File-Checksum-Failed {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "checksum failed.`n`n"
	}}


	# report status
	return 0
}