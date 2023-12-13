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

. "${env:LIBS_AUTOMATACI}\services\i18n\_status-file-archive.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_status-file-check.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_status-file-create.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_status-file-update.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_status-file-validate.ps1"




function I18N-Status-Print-File-Assemble {
	param(
		[string]$___subject,
		[string]$___target
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$___target = I18N-Status-Param-Process "${___target}"
		$null = I18N-Status-Print info `
			"assembling file: ${___subject} as ${___target}`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-File-Detected {
	param(
		[string]$___subject
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$null = I18N-Status-Print info "detected file: ${___subject}`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-File-Incompatible-Skipped {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print warning "incompatible file. Skipping...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-File-Injected {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print warning "manual injection detected.`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-File-Bad-Stat-Skipped {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print warning "failed to parse file. Skipping...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-File-Write-Failed {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "write failed.`n`n"
	}}


	# report status
	return 0
}
