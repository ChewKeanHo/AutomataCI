# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\changelog.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return
}




function PACKAGE-Run-CHANGELOG {
	param (
		[string]$__changelog_md,
		[string]$__changelog_deb
	)


	$null = I18N-Status-Print-Check-Availability "CHANGELOG"
	$__process = CHANGELOG-Is-Available
	if ($__process -ne 0) {
		$null = I18N-Status-Print-File-Check-Failed
		return 1
	}


	# validate input
	$null = I18N-Status-Print-File-Validate "${env:PROJECT_VERSION} CHANGELOG"
	$__process = CHANGELOG-Compatible-DATA-Version `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\changelog" `
		"${env:PROJECT_VERSION}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-File-Validate-Failed
		return 1
	}

	$null = I18N-Status-Print-File-Validate "${env:PROJECT_VERSION} DEB CHANGELOG"
	$__process = CHANGELOG-Compatible-DEB-Version `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\changelog" `
		"${env:PROJECT_VERSION}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-File-Validate-Failed
		return 1
	}


	# assemble changelog
	$null = I18N-Status-Print-File-Create "${__changelog_md}"
	$__process = CHANGELOG-Assemble-MD `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\changelog" `
		"${__changelog_md}" `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_CHANGELOG_TITLE}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-File-Create-Failed
		return 1
	}

	$null = I18N-Status-Print-File-Create "${__changelog_deb}"
	$null = FS-Make-Housing-Directory "${__changelog_deb}"
	$__process = CHANGELOG-Assemble-DEB `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\changelog" `
		"${__changelog_deb}" `
		"${env:PROJECT_VERSION}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-File-Create-Failed
		return 1
	}


	# report status
	return 0
}
