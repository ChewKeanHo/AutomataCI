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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\flatpak.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




function PACKAGE-Run-FLATPAK {
	param (
		[string]$_dest,
		[string]$_target,
		[string]$_target_filename,
		[string]$_target_os,
		[string]$_target_arch,
		[string]$_repo
	)

	OS-Print-Status info "checking FLATPAK functions availability..."
	$__process = FLATPAK-Is-Available "${_target_os}" "${_target_arch}"
	switch ($__process) {
	2 {
		OS-Print-Status warning "FLATPAK is incompatible (OS type). Skipping."
		return 0
	} 3 {
		OS-Print-Status warning "FLATPAK is incompatible (CPU type). Skipping."
		return 0
	} 0 {
		break
	} Default {
		OS-Print-Status warning "FLATPAK is unavailable. Skipping."
		return 0
	}}


	# prepare workspace and required values
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}.flatpak"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\flatpak_${_src}"
	OS-Print-Status info "Creating FLATPAK package..."
	OS-Print-Status info "remaking workspace directory ${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		OS-Print-Status error "remake failed."
		return 1
	}

	OS-Print-Status info "checking output file existence..."
	if (Test-Path -Path "${_target_path}" -PathType Container) {
		OS-Print-Status error "check failed - output exists!"
		return 1
	}

	# copy all complimentary files to the workspace
	OS-Print-Status info "assembling package files..."
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-FLATPAK-Content"
	if ($__process -ne 0) {
		OS-Print-Status error "missing PACKAGE-Assemble-FLATPAK-Content function."
		return 1
	}
	$__process = PACKAGE-Assemble-FLATPAK-Content `
			"${_target}" `
			"${_src}" `
			"${_target_filename}" `
			"${_target_os}" `
			"${_target_arch}"
	if ($__process -eq 10) {
		$null = FS-Remove-Silently ${_src}
		OS-Print-Status warning "packaging is not required. Skipping process."
		return 0
	} elseif ($__process -ne 0) {
		OS-Print-Status error "assembly failed."
		return 1
	}

	# generate required files
	OS-Print-Status info "creating manifest file..."
	$__process = FLATPAK-Create-Manifest `
		"${_src}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}" `
		"${env:PROJECT_APP_ID}" `
		"${env:PROJECT_SKU}" `
		"${_target_arch}" `
		"${env:PROJECT_FLATPAK_RUNTIME}" `
		"${env:PROJECT_FLATPAK_RUNTIME_VERSION}" `
		"${env:PROJECT_FLATPAK_SDK}"
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	OS-Print-Status info "creating AppInfo XML file..."
	$__process = FLATPAK-Create-AppInfo `
		"${_src}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	# archive the assembled payload
	OS-Print-Status info "archiving .flatpak package..."
	$null = FS-Make-Directory "${_target_path}"
	$__process = FLATPAK-Create-Archive `
		"${_src}" `
		"${_target_path}" `
		"${env:PROJECT_APP_ID}" `
		"${env:PROJECT_GPG_ID}"
	if ($__process -ne 0) {
		OS-Print-Status error "package failed."
		return 1
	}

	# report status
	return 0
}
