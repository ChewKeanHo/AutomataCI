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
. "${env:LIBS_AUTOMATACI}\services\compilers\rpm.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\createrepo.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Run-RPM {
	param(
		[string]$__target,
		[string]$__directory
	)


	# validate input
	$___process = RPM-Is-Valid "${__target}"
	if ($___process -ne 0) {
		return 0
	}

	$null = I18N-Check-Availability "CREATEREPO"
	$___process = CREATEREPO-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Check-Failed-Skipped
		return 0
	}


	# execute
	$__dest = "${__directory}/rpm"
	$null = I18N-Create "${__dest}"
	$___process = FS-Make-Directory "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}

	$null = I18N-Publish "CREATEREPO"
	$___process = CREATEREPO-Publish "${__target}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Publish-Failed
		return 1
	}


	# report status
	return 0
}
