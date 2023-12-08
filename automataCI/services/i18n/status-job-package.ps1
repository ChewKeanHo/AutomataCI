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

. "${env:LIBS_AUTOMATACI}\services\i18n\_status-job-package-assembler.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_status-job-package-export.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_status-job-package-parallelism.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_status-job-package-remake.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\_status-job-package-source.ps1"




function I18N-Status-Print-Package-Create {
	param(
		[string]$___subject
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$null = I18N-Status-Print info "creating ${___subject} package...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Package-Exec {
	param(
		[string]$___subject
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$null = I18N-Status-Print info "packaging ${___subject}...`n"
	}}


	# report status
	return 0
}




function I18N-Status-Print-Package-Exec-Failed {
	param(
		[string]$___subject
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		# fallback to default english
		$___subject = I18N-Status-Param-Process "${___subject}"
		$null = I18N-Status-Print error "package failed - ${___subject}`n`n"
	}}


	# report status
	return 0
}
