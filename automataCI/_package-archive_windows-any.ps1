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
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return
}




function PACKAGE-Run-ARCHIVE {
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
	$null = I18N-Status-Print-Check-Availability "TAR"
	$__process = TAR-Is-Available
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "TAR"
		return 1
	}

	$null = I18N-Status-Print-Check-Availability "ZIP"
	$__process = ZIP-Is-Available
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "ZIP"
		return 1
	}


	# prepare workspace and required values
	$null = I18N-Status-Print-Package-Create "ARCHIVE"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\archive_${_src}"
	$null = I18N-Status-Print-Package-Workspace-Remake "${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}


	# copy all complimentary files to the workspace
	$cmd = "PACKAGE-Assemble-ARCHIVE-Content"
	$null = I18N-Status-Print-Package-Assembler-Check "$cmd"
	$__process = OS-Is-Command-Available "$cmd"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Check-Failed
		return 1
	}

	$null = I18N-Status-Print-Package-Assembler-Exec
	$__process = PACKAGE-Assemble-ARCHIVE-Content `
		${_target} `
		${_src} `
		${_target_filename} `
		${_target_os} `
		${_target_arch}
	switch ($__process) {
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


	# change location into the workspace
	$__current_path = Get-Location
	$null = Set-Location -Path "${_src}"


	# archive the assembled payload
	switch ($_target_os) {
	windows {
		$_target_path = "${_target_path}.zip"
		$null = I18N-Status-Print-Package-Exec "${_target_path}"
		$__process = ZIP-Create "${_target_path}" "*"
	} Default {
		$_target_path = "${_target_path}.tar.xz"
		$null = I18N-Status-Print-Package-Exec "${_target_path}"
		$__process = TAR-Create-XZ "${_target_path}" "*"
	}}


	# head back to current directory
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path


	# report status
	if ($__process -ne 0) {
		return 1
	}

	return 0
}
