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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\tar.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\zip.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




function PACKAGE-Run-Archive {
	param (
		[string]$_dest,
		[string]$_target,
		[string]$_target_filename,
		[string]$_target_os,
		[string]$_target_arch
	)


	OS-Print-Status info "checking tar functions availability..."
	$__process = TAR-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "checking failed."
		return 1
	}

	OS-Print-Status info "checking zip functions availability..."
	$__process = ZIP-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "checking failed."
		return 1
	}


	# prepare workspace and required values
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\archive_${_src}"
	OS-Print-Status info "archiving ${_src} for ${_target_os}-${_target_arch}"
	OS-Print-Status info "remaking workspace directory ${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		OS-Print-Status error "remake failed."
		return 1
	}


	# copy all complimentary files to the workspace
	OS-Print-Status info "assembling package files..."
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-Archive-Content"
	if ($__process -ne 0) {
		OS-Print-Status error "missing PACKAGE-Assemble-Archive-Content function."
		return 1
	}
	$__process = PACKAGE-Assemble-Archive-Content `
		${_target} `
		${_src} `
		${_target_filename} `
		${_target_os} `
		${_target_arch}
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


	# change location into the workspace
	$__current_path = Get-Location
	$null = Set-Location -Path "${_src}"


	# archive the assembled payload
	switch ($_target_os) {
	windows {
		$_target_path = "${_target_path}.zip"
		OS-Print-Status info "packaging ${_target_path}"
		$__process = ZIP-Create "${_target_path}" "*"
	} Default {
		$_target_path = "${_target_path}.tar.xz"
		OS-Print-Status info "packaging ${_target_path}"
		$__process = TAR-Create-XZ "${_target_path}" "*"
	}}


	# head back to current directory
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path


	# report status
	if ($__process -eq 0) {
		return 0
	}

	OS-Print-Status error "package failed."
	return 1
}
