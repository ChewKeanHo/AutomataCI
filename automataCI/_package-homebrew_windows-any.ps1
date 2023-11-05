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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\tar.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\checksum\shasum.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




function PACKAGE-Run-Homebrew {
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
	OS-Print-Status info "checking tar functions availability..."
	$__process = TAR-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "checking failed."
		return 1
	}


	# prepare workspace and required values
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\homebrew_${_src}"
	OS-Print-Status info "creating homebrew source package..."
	OS-Print-Status info "remaking workspace directory ${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		OS-Print-Status error "remake failed."
		return 1
	}


	# copy all complimentary files to the workspace
	OS-Print-Status info "checking PACKAGE-Assemble-HOMEBREW-Content function..."
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-HOMEBREW-Content"
	if ($__process -ne 0) {
		OS-Print-Status error "missing PACKAGE-Assemble-HOMEBREW-Content function."
		return 1
	}

	OS-Print-Status info "assembling package files..."
	$__process = PACKAGE-Assemble-HOMEBREW-Content `
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


	# check formula.rb is available
	OS-Print-Status info "checking formula.rb availability..."
	$__process = FS-Is-File "${_src}/formula.rb"
	if ($__process -ne 0) {
		OS-Print-Status error "check failed."
		return 1
	}


	# archive the assembled payload
	$__current_path = Get-Location
	$null = Set-Location -Path "${_src}"
	OS-Print-Status info "archiving ${_target_path}.tar.xz"
	$__process = TAR-Create-XZ "${_target_path}.tar.xz" "*"
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path
	if ($__process -ne 0) {
		OS-Print-Status error "archive failed."
		return 1
	}


	# sha256 the package
	OS-Print-Status info "shasum the package with sha256 algorithm..."
	$__shasum = SHASUM-Checksum-File "${_target_path}.tar.xz" "256"
	if ([string]::IsNullOrEmpty($__shasum)) {
		OS-Print-Status error "shasum failed."
		return 1
	}


	# update the formula.rb script
	OS-Print-Status info "update given formula.rb file..."
	$null = FS-Remove-Silently "${_target_path}.rb"
	foreach ($__line in (Get-Content "${_src}\formula.rb")) {
		$__line = STRINGS-Replace-All `
			"${__line}" `
			"{{ TARGET_PACKAGE }}" `
			"$(Split-Path -Leaf -Path "${_target_path}.tar.xz")"

		$__line = STRINGS-Replace-All `
			"${__line}" `
			"{{ TARGET_SHASUM }}" `
			"${__shasum}"

		$__process = FS-Append-File "${_target_path}.rb" "${__line}"
		if ($__process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}
