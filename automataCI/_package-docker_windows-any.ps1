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
. "${env:LIBS_AUTOMATACI}\services\compilers\docker.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return 1
}




function PACKAGE-Run-DOCKER {
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
	$null = I18N-Status-Print-Check-Availability "DOCKER"
	$___process = DOCKER-Is-Available
	switch ($___process) {
	{ $_ -in 2, 3 } {
		$null = I18N-Status-Print-Check-Availability-Incompatible "DOCKER"
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Status-Print-Check-Availability-Failed "DOCKER"
		return 0
	}}


	# prepare workspace and required values
	$null = I18N-Status-Print-Package-Create "DOCKER"
	$_src = "${__target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\docker.txt"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\docker_${_src}"
	$null = I18N-Status-Print-Package-Workspace-Remake "${_src}"
	$___process = FS-Remake-Directory "${_src}"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}


	# copy all complimentary files to the workspace
	$cmd = "PACKAGE-Assemble-DOCKER-Content"
	$null = I18N-Status-Print-Package-Assembler-Check "${cmd}"
	$___process = OS-Is-Command-Available "$cmd"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Package-Check-Failed
		return 1
	}

	$null = I18N-Status-Print-Package-Assembler-Exec
	$___process = PACKAGE-Assemble-DOCKER-Content `
		"${_target}" `
		"${_src}" `
		"${_target_filename}" `
		"${_target_os}" `
		"${_target_arch}"
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


	# check required files
	$null = I18N-Status-Print-File-Check-Exists "${_src}/Dockerfile"
	$___process = FS-Is-File "${_src}/Dockerfile"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-File-Check-Failed
		return 1
	}


	# change location into the workspace
	$__current_path = Get-Location
	$null = Set-Location -Path "${_src}"


	# archive the assembled payload
	$null = I18N-Status-Print-Package-Exec "${_target_path}"
	$___process = DOCKER-Create `
		"${_target_path}" `
		"${_target_os}" `
		"${_target_arch}" `
		"${env:PROJECT_CONTAINER_REGISTRY}" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_VERSION}"
	if ($___process -ne 0) {
		$null = Set-Location -Path "${__current_path}"
		$null = Remove-Variable -Name __current_path
		$null = I18N-Status-Print-Package-Exec-Failed "${_target_path}"
		return 1
	}


	# logout
	$null = I18N-Status-Print-Run-Logout "DOCKER"
	$___process = DOCKER-Logout
	if ($___process -ne 0) {
		$null = Set-Location -Path "${___current_path}"
		$null = Remove-Variable -Name ___current_path
		$null = I18N-Status-Print-Run-Logout-Failed
		return 1
	}

	$null = I18N-Status-Print-Run-Clean "DOCKER"
	$___process = DOCKER-Clean-Up
	if ($___process -ne 0) {
		$null = Set-Location -Path "${___current_path}"
		$null = Remove-Variable -Name ___current_path
		$null = I18N-Status-Print-Run-Clean-Failed
		return 1
	}


	# head back to current directory
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path


	# report status
	return 0
}
