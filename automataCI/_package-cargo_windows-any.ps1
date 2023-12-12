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
. "${env:LIBS_AUTOMATACI}\services\compilers\rust.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return
}




function PACKAGE-Run-CARGO {
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
	if ($(STRINGS-Is-Empty "${env:PROJECT_RUST}") -eq 0) {
		$null = RUST-Activate-Local-Environment
	}

	$null = I18N-Status-Print-Check-Availability "RUST"
	$__process = RUST-Is-Available
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "RUST"
		return 0
	}


	# prepare workspace and required values
	$null = I18N-Status-Print-Package-Create "RUST"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\cargo_${_src}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\cargo_${_src}"
	$null = I18N-Status-Print-Package-Workspace-Remake "${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}

	$null = I18N-Status-Print-File-Check-Exists "${_target_path}"
	$__process = FS-Is-Directory "${_target_path}"
	if ($__process -eq 0) {
		$null = I18N-Status-Print-File-Check-Failed
		return 1
	}


	# copy all complimentary files to the workspace
	$cmd = "PACKAGE-Assemble-CARGO-Content"
	$null = I18N-Status-Print-Package-Assembler-Check "${cmd}"
	$__process = OS-Is-Command-Available "${cmd}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Check-Failed
		return 1
	}

	$null = I18N-Status-Print-Package-Assembler-Exec
	$__process = PACKAGE-Assemble-CARGO-Content `
			${_target} `
			${_src} `
			${_target_filename} `
			${_target_os} `
			${_target_arch}
	if ($__process -eq 10) {
		$null = I18N-Status-Print-Package-Assembler-Exec-Skipped
		$null = FS-Remove-Silently ${_src}
		return 0
	} elseif ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Assembler-Exec-Failed
		return 1
	}


	# archive the assembled payload
	$null = I18N-Status-Print-Package-Exec "${_target_path}"
	$null = FS-Make-Directory "${_target_path}"
	$__process = RUST-Create-Archive "${_src}" "${_target_path}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Exec-Failed "${_target_path}"
		return 1
	}


	# report status
	return 0
}
