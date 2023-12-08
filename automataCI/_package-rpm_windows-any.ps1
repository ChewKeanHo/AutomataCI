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
. "${env:LIBS_AUTOMATACI}\services\compilers\copyright.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\manual.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\rpm.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return
}




function PACKAGE-Run-RPM {
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
	$null = I18N-Status-Print-Check-Availability "RPM"
	$__process = RPM-Is-Available "${_target_os}" "${_target_arch}"
	switch ($__process) {
	{ $_ -in 2, 3 } {
		$null = I18N-Status-Print-Check-Availability-Incompatible "RPM"
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Status-Print-Check-Availability-Failed "RPM"
		return 0
	}}

	$null = I18N-Status-Print-Check-Availability "MANUAL DOCS"
	$__process = MANUAL-Is-Available
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "MANUAL DOCS"
		return 1
	}


	# prepare workspace and required values
	$null = I18N-Status-Print-Package-Create "RPM"
	$_src = "${_target_filename}_${_target_os}-${_target_arch}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\rpm_${_src}"
	$null = I18N-Status-Print-Package-Workspace-Remake "${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}
	$null = FS-Make-Directory "${_src}/BUILD"
	$null = FS-Make-Directory "${_src}/SPECS"


	# copy all complimentary files to the workspace
	$cmd = "PACKAGE-Assemble-RPM-Content"
	$null = I18N-Status-Print-Package-Assembler-Check "$cmd"
	$__process = OS-Is-Command-Available "$cmd"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Check-Failed
		return 1
	}

	$___process = PACKAGE-Assemble-RPM-Content `
		${_target} `
		${_src} `
		${_target_filename} `
		${_target_os} `
		${_target_arch}
	switch ($___process) {
	10 {
		$null = I18N-Status-Print-Package-Assembler-Exec-Skipped
		$null = FS-Remove-Silently ${_src}
		return 0
	} 0 {
		# accepted
	} default {
		$null = I18N-Status-Print-Package-Assembler-Exec-Failed
		return 1
	}}


	# archive the assembled payload
	$null = I18N-Status-Print-Package-Exec "${_dest}"
	$__process = RPM-Create-Archive "${_src}" "${_dest}" "${_target_arch}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Exec-Failed "${_dest}"
		return 1
	}


	# report status
	return 0
}
