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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\flatpak.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function PACKAGE-Run-FLATPAK {
	param (
		[string]$__line
	)


	# parse input
	$__list = $__line -split "\|"
	$_dest = $__list[0]
	$_target = $__list[1]
	$_target_filename = $__list[2]
	$_target_os = $__list[3]
	$_target_arch = $__list[4]
	$_repo = $__list[5]


	# validate input
	$null = I18N-Check-Availability "FLATPAK"
	$___process = FLATPAK-Is-Available "${_target_os}" "${_target_arch}"
	switch ($___process) {
	2 {
		$null = I18N-Check-Incompatible-Skipped
		return 0
	} { $_ -in 0, 3 } {
		break
	} Default {
		$null = I18N-Check-Failed
		return 0
	}}


	# prepare workspace and required values
	$null = I18N-Create-Package "FLATPAK"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}.flatpak"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\packagers-flatpak-${_src}"
	$null = I18N-Remake "${_src}"
	$___process = FS-Remake-Directory "${_src}"
	if ($___process -ne 0) {
		$null = I18N-Remake-Failed
		return 1
	}

	$null = I18N-Check "${_target_path}"
	if ($(FS-Is-File "${_target_path}") -eq 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# copy all complimentary files to the workspace
	$cmd = "PACKAGE-Assemble-FLATPAK-Content"
	$null = I18N-Check-Function "$cmd"
	$___process = OS-Is-Command-Available "$cmd"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$null = I18N-Assemble-Package
	$___process = PACKAGE-Assemble-FLATPAK-Content `
			"${_target}" `
			"${_src}" `
			"${_target_filename}" `
			"${_target_os}" `
			"${_target_arch}"
	switch ($___process) {
	10 {
		$null = I18N-Assemble-Skipped
		$null = FS-Remove-Silently "${_src}"
		return 0
	} 0 {
		# accepted
	} default {
		$null = I18N-Assemble-Failed
	}}


	# generate required files
	$null = I18N-Check "${_src}\manifest.yml"
	$___process = FS-Is-File "${_src}\manifest.yml"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$null = I18N-Check "${_src}\appdata.xml"
	$___process = FS-Is-File "${_src}\appdata.xml"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# archive the assembled payload
	$null = I18N-Package "${_target_path}"
	$___process = FLATPAK-Create-Archive `
		"${_src}" `
		"${_target_path}" `
		"${_repo}" `
		"${env:PROJECT_APP_ID}" `
		"${env:PROJECT_GPG_ID}"
	if ($___process -ne 0) {
		$null = I18N-Package-Failed "${_target_path}"
		return 1
	}


	# report status
	return 0
}
