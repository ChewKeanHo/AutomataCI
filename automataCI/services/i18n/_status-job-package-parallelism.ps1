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




function I18N-Status-Print-Package-Parallelism-Register {
	param(
		[string]$___subject
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$null = I18N-Status-Print info `
			"registering for packaging in parallel: ${___subject}`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Package-Parallelism-Log {
	param(
		[string]$___subject
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$null = I18N-Status-Print info "log report from ${___subject}`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Package-Parallelism-Run {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print info "executing parallel run...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Package-Parallelism-Run-Skipped {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print warning "no instruction found. Skipping...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Package-Parallelism-Run-Failed {
	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$null = I18N-Status-Print error "exec failed.`n`n"
	}}


	# report status
	return 0
}
