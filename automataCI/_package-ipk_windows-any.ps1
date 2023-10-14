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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\ipk.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




function PACKAGE-Run-IPK {
	param (
		[string]$_dest,
		[string]$_target,
		[string]$_target_filename,
		[string]$_target_os,
		[string]$_target_arch
	)

	OS-Print-Status info "checking ipk functions availability..."
	$__process = IPK-Is-Available "${_target_os}" "${_target_arch}"
	switch ($__process) {
	2 {
		OS-Print-Status warning "IPK is incompatible (OS type). Skipping."
		return 0
	} 3 {
		OS-Print-Status warning "IPK is incompatible (CPU type). Skipping."
		return 0
	} 0 {
		break
	} Default {
		OS-Print-Status warning "IPK is unavailable. Skipping."
		return 0
	}}


	# prepare workspace and required values
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}.ipk"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\ipk_${_src}"
	OS-Print-Status info "Creating IPK package..."
	OS-Print-Status info "remaking workspace directory ${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		OS-Print-Status error "remake failed."
		return 1
	}
	$null = FS-Make-Directory "${_src}\control"
	$null = FS-Make-Directory "${_src}\data"


	# execute
	OS-Print-Status info "checking output file existence..."
	$__process = FS-Is-File "${_target_path}"
	if ($__process -eq 0) {
		OS-Print-Status error "check failed - output exists!"
		return 1
	}

	OS-Print-Status info "checking PACKAGE-Assemble-IPK-Content function..."
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-IPK-Content"
	if ($__process -ne 0) {
		OS-Print-Status error "check failed."
		return 1
	}

	OS-Print-Status info "assembling package files..."
	$__process = PACKAGE-Assemble-IPK-Content `
		"${_target}" `
		"${_src}" `
		"${_target_filename}" `
		"${_target_os}" `
		"${_target_arch}"
	switch ($__process) {
	10 {
		$null = FS-Remove-Silently "${_src}"
		OS-Print-Status warning "packaging is not required. Skipping process."
		return 0
	} 0 {
		# accepted
	} Default {
		OS-Print-Status error "assembly failed."
		return 1
	}}

	OS-Print-Status info "checking control\control file..."
	$__process = FS-Is-File "${_src}\control\control"
	if ($__process -ne 0) {
		OS-Print-Status error "check failed."
		return 1
	}

	OS-Print-Status info "archiving .ipk package..."
	$__process = IPK-Create-Archive "${_src}" "${_target_path}"
	if ($__process -ne 0) {
		OS-Print-Status error "package failed."
		return 1
	}


	# report status
	return 0
}