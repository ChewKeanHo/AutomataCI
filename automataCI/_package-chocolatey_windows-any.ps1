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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\chocolatey.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




function PACKAGE-Run-Chocolatey {
	param (
		[string]$_dest,
		[string]$_target,
		[string]$_target_filename,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate input
	OS-Print-Status info "checking zip functions availability..."
	$__process = ZIP-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "checking failed."
		return 1
	}


	# prepare workspace and required values
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\choco_${_src}"
	OS-Print-Status info "creating chocolatey source package..."
	OS-Print-Status info "remaking workspace directory ${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		OS-Print-Status error "remake failed."
		return 1
	}


	# copy all complimentary files to the workspace
	OS-Print-Status info "checking PACKAGE-Assemble-CHOCOLATEY-Content function..."
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-CHOCOLATEY-Content"
	if ($__process -ne 0) {
		OS-Print-Status error "missing PACKAGE-Assemble-CHOCOLATEY-Content function."
		return 1
	}

	OS-Print-Status info "assembling package files..."
	$__process = PACKAGE-Assemble-CHOCOLATEY-Content `
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


	# check nuspec is available
	OS-Print-Status info "checking .nuspec metadata file availability..."
	$__name = ""
	foreach ($__file in (Get-ChildItem -File -Path "${_src}\*.nuspec")) {
		if (-not ([string]::IsNullOrEmpty($__name))) {
			OS-Print-Status error "check failed - multiple files."
			return 1
		}

		$__name = $__file.Name -replace '\.nuspec.*$', ''
	}

	if ([string]::IsNullOrEmpty($__name)) {
		OS-Print-Status error "check failed."
		return 1
	}


	# archive the assembled payload
	$__name = "${__name}-chocolatey_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}.nupkg"
	$__name = "${_dest}\${__name}"
	OS-Print-Status info "archiving ${__name}"
	$__process = CHOCOLATEY-Archive "${__name}" "${_src}"
	if ($__process -ne 0) {
		OS-Print-Status error "archive failed."
		return 1
	}


	# test the package
	OS-Print-Status info "testing ${__name}"
	$__process = CHOCOLATEY-Is-Available
	if ($__process -eq 0) {
		$__process = CHOCOLATEY-Test "${__name}"
		if ($__process -ne 0) {
			OS-Print-Status error "test failed."
			return 1
		}
	} else {
		OS-Print-Status warning "test skipped."
	}


	# report status
	return 0
}
