# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Run-CITATION-CFF {
	param(
		[string]$_target
	)


	# validate input
	$___process = FS-Is-Target-A-Citation-CFF "${_target}"
	if ($___process -ne 0) {
		return 0
	}


	# execute
	$null = I18N-Export "CITATION.cff"
	$___process = FS-Copy-File "${_target}" "${env:PROJECT_PATH_ROOT}\CITATION.cff"
	if ($___process -ne 0) {
		$null = I18N-Export-Failed
		return 1
	}


	# report status
	return 0
}
