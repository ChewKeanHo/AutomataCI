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




function I18N-Status-Print-Run-Failed {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "CI job - run failed.`n`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Run-Successful {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print success "`n`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Run-CI-Job {
	param(
		[string]$___subject
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$null = I18N-Status-Print info "${___subject} job recipe detected. Running...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Run-CI-Job-Validate {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print info "validating CI job...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Run-CI-Job-Validate-Failed {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "validating failed.`n`n"
	}}


	# report status
	return 0
}
