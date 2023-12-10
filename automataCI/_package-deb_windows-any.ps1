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
. "${env:LIBS_AUTOMATACI}\services\compilers\deb.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return
}




function PACKAGE-Run-DEB {
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
	$_changelog_deb = $__list[5]


	# validate input
	$null = I18N-Status-Print-Check-Availability "DEB"
	$__process = DEB-Is-Available "${_target_os}" "${_target_arch}"
	switch ($__process) {
	{ $_ -in 2, 3 } {
		$null = I18N-Status-Print-Check-Availability-Incompatible "DEB"
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Status-Print-Check-Availability-Failed "DEB"
		return 0
	}}


	# prepare workspace and required values
	$null = I18N-Status-Print-Package-Create "DEB"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}.deb"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb_${_src}"
	$null = I18N-Status-Print-Package-Workspace-Remake "${_src}"
	$___process = FS-Remake-Directory "${_src}"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}
	$null = FS-Make-Directory "${_src}\control"
	$null = FS-Make-Directory "${_src}\data"


	# execute
	$null = I18N-Status-Print-File-Check-Exists "${_target_path}"
	$___process = FS-Is-File "${_target_path}"
	if ($___process -eq 0) {
		$null = I18N-Status-Print-File-Check-Failed
		return 1
	}

	$cmd = "PACKAGE-Assemble-DEB-Content"
	$null = I18N-Status-Print-Package-Assembler-Check "$cmd"
	$___process = OS-Is-Command-Available "$cmd"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Package-Check-Failed
		return 1
	}

	$null = I18N-Status-Print-Package-Assembler-Exec
	$___process = PACKAGE-Assemble-DEB-Content `
		"${_target}" `
		"${_src}" `
		"${_target_filename}" `
		"${_target_os}" `
		"${_target_arch}" `
		"${_changelog_deb}"
	switch ($___process) {
	10 {
		$null = I18N-Status-Print-Package-Assembler-Exec-Skipped
		$null = FS-Remove-Silently "${_src}"
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Status-Print-Package-Assembler-Exec-Failed
		return 1
	}}

	$null = I18N-Status-Print-File-Check-Exists "${_src}\control\md5sums"
	$___process = FS-Is-File "${_src}\control\md5sums"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-File-Check-Failed
		return 1
	}

	$null = I18N-Status-Print-File-Check-Exists "${_src}\control\control"
	$___process = FS-Is-File "${_src}\control\control"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-File-Check-Failed
		return 1
	}

	$null = I18N-Status-Print-Package-Exec "${_target_path}"
	$___process = DEB-Create-Archive "${_src}" "${_target_path}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
