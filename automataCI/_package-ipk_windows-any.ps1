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
. "${env:LIBS_AUTOMATACI}\services\compilers\ipk.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return
}




function PACKAGE-Run-IPK {
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


	# validate input
	$null = I18N-Check-Availability "IPK"
	$__process = IPK-Is-Available "${_target_os}" "${_target_arch}"
	switch ($__process) {
	{ $_ -in 2, 3 } {
		$null = I18N-Check-Incompatible-Skipped
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Check-Failed
		return 0
	}}


	# prepare workspace and required values
	$null = I18N-Create-Package "IPK"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}.ipk"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\ipk_${_src}"
	$null = I18N-Remake "${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		$null = I18N-Remake-Failed
		return 1
	}
	$null = FS-Make-Directory "${_src}\control"
	$null = FS-Make-Directory "${_src}\data"


	# execute
	$null = I18N-Check "${_target_path}"
	$__process = FS-Is-File "${_target_path}"
	if ($__process -eq 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$cmd = "PACKAGE-Assemble-IPK-Content"
	$null = I18N-Check-Function "$cmd"
	$__process = OS-Is-Command-Available "$cmd"
	if ($__process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$null = I18N-Assemble-Package
	$__process = PACKAGE-Assemble-IPK-Content `
		"${_target}" `
		"${_src}" `
		"${_target_filename}" `
		"${_target_os}" `
		"${_target_arch}"
	switch ($__process) {
	10 {
		$null = I18N-Assemble-Skipped
		$null = FS-Remove-Silently "${_src}"
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Assemble-Failed
		return 1
	}}

	$null = I18N-Check "control\control"
	$__process = FS-Is-File "${_src}\control\control"
	if ($__process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$null = I18N-Package "${_target_path}"
	$__process = IPK-Create-Archive "${_src}" "${_target_path}"
	if ($__process -ne 0) {
		$null = I18N-Package-Failed
		return 1
	}


	# report status
	return 0
}
