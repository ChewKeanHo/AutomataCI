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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\copyright.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\manual.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\deb.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




function PACKAGE-Run-DEB {
	param (
		[string]$_dest,
		[string]$_target,
		[string]$_target_filename,
		[string]$_target_os,
		[string]$_target_arch,
		[string]$_changelog_deb
	)

	OS-Print-Status info "checking deb functions availability..."
	$__process = DEB-Is-Available "${_target_os}" "${_target_arch}"
	switch ($__process) {
	2 {
		OS-Print-Status warning "DEB is incompatible (OS type). Skipping."
		return 0
	} 3 {
		OS-Print-Status warning "DEB is incompatible (CPU type). Skipping."
		return 0
	} 0 {
		break
	} Default {
		OS-Print-Status warning "DEB is unavailable. Skipping."
		return 0
	}}

	OS-Print-Status info "checking manual docs functions availability..."
	$__process = MANUAL-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status warning "Man docs functions is unavailable. Skipping."
		return 1
	}


	# prepare workspace and required values
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}.deb"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb_${_src}"
	OS-Print-Status info "Creating DEB package..."
	OS-Print-Status info "remaking workspace directory ${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		OS-Print-Status error "remake failed."
		return 1
	}
	$null = FS-Make-Directory "${_src}\control"
	$null = FS-Make-Directory "${_src}\data"

	OS-Print-Status info "checking output file existence..."
	if (Test-Path -Path "${_target_path}") {
		OS-Print-Status error "check failed - output exists!"
		return 1
	}


	# copy all complimentary files to the workspace
	OS-Print-Status info "assembling package files..."
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-DEB-Content"
	if ($__process -ne 0) {
		OS-Print-Status error "missing PACKAGE-Assemble-DEB-Content function."
		return 1
	}
	$__process = PACKAGE-Assemble-DEB-Content `
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


	# generate required files
	OS-Print-Status info "creating copyright.gz file..."
	$__process = COPYRIGHT-Create-DEB `
		${_src} `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\licenses\deb-copyright" `
		${env:PROJECT_DEBIAN_IS_NATIVE} `
		${env:PROJECT_SKU} `
		${env:PROJECT_CONTACT_NAME} `
		${env:PROJECT_CONTACT_EMAIL} `
		${env:PROJECT_CONTACT_WEBSITE}
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	OS-Print-Status info "creating changelog.gz file..."
	DEB-Create-Changelog `
		${_src} `
		"${_changelog_deb}" `
		${env:PROJECT_DEBIAN_IS_NATIVE} `
		${env:PROJECT_SKU}
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	OS-Print-Status info "creating man page files..."
	MANUAL-Create-DEB-Manpage `
		${_src} `
		${env:PROJECT_DEBIAN_IS_NATIVE} `
		${env:PROJECT_SKU} `
		${env:PROJECT_CONTACT_NAME} `
		${env:PROJECT_CONTACT_EMAIL} `
		${env:PROJECT_CONTACT_WEBSITE}
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	OS-Print-Status info "creating control/md5sums file..."
	DEB-Create-Checksum "${_src}"
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	OS-Print-Status info "creating control/control file..."
	DEB-Create-Control `
		"${_src}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_VERSION}" `
		"${_target_arch}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_PITCH}" `
		"${env:PROJECT_DEBIAN_PRIORITY}" `
		"${env:PROJECT_DEBIAN_SECTION}"
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}


	# archive the assembled payload
	OS-Print-Status info "archiving .deb package..."
	$__process = DEB-Create-Archive "${_src}" "${_target_path}"
	if ($__process -ne 0) {
		OS-Print-Status error "package failed."
		return 1
	}


	# report status
	return 0
}
