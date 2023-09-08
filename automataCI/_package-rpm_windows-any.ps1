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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\rpm.ps1"




function PACKAGE-Run-RPM {
	param (
		[string]$_dest,
		[string]$_target,
		[string]$_target_filename,
		[string]$_target_os,
		[string]$_target_arch
	)

	OS-Print-Status info "checking rpm functions availability..."
	$__process = RPM-Is-Available
	switch ($__process) {
	2 {
		OS-Print-Status warning "RPM is incompatible (OS type). Skipping."
		return 0
	} 3 {
		OS-Print-Status warning "RPM is incompatible (CPU type). Skipping."
		return 0
	} 0 {
		break
	} Default {
		OS-Print-Status warning "RPM is unavailable. Skipping."
		return 0
	}}

	OS-Print-Status info "checking manual docs functions availability..."
	$__process = MANUAL-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "checking failed."
		return 1
	}

	# prepare workspace and required values
	$__process = FS-Is-Target-A-Source "${_target}"
	if ($__process -eq 0) {
		$_src = "rpm-src_${PROJECT_SKU}_${_target_os}-${_target_arch}"
	} else {
		$_src = "rpm_${PROJECT_SKU}_${_target_os}-${_target_arch}"
	}
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${_src}"
	OS-Print-Status info "Creating RPM package..."
	OS-Print-Status info "remaking workspace directory ${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		OS-Print-Status error "remake failed."
		return 1
	}
	$null = FS-Make-Directory "${_src}/BUILD"
	$null = FS-Make-Directory "${_src}/SPECS"

	# copy all complimentary files to the workspace
	OS-Print-Status info "assembling package files..."
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-RPM-Content"
	if ($__process -ne 0) {
		OS-Print-Status error "missing PACKAGE-Assemble-RPM-Content function."
		return 1
	}
	$__process = PACKAGE-Assemble-RPM-Content `
		${_target} `
		${_src} `
		${_target_filename} `
		${_target_os} `
		${_target_arch}
	if ($__process -eq 10) {
		$null = FS-Remove-Silently ${_src}
		OS-Print-Status warning "packaging is not required. Skipping process."
		return 0
	} elseif ($__process -ne 0) {
		OS-Print-Status error "assembly failed."
		return 1
	}

	# generate required files
	OS-Print-Status info "creating copyright.gz file..."
	$__process = COPYRIGHT-Create-RPM `
		${_src} `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\licenses\deb-copyright" `
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

	OS-Print-Status info "creating man pages file..."
	MANUAL-Create-RPM_Manpage `
		${_src} `
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

	OS-Print-Status info "creating spec file..."
	RPM-Create-Spec `
		${_src} `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}" `
		${env:PROJECT_SKU} `
		${env:PROJECT_VERSION} `
		${env:PROJECT_CADENCE} `
		${env:PROJECT_PITCH} `
		${env:PROJECT_CONTACT_NAME} `
		${env:PROJECT_CONTACT_EMAIL} `
		${env:PROJECT_CONTACT_WEBSITE}
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	# archive the assembled payload
	OS-Print-Status info "archiving .rpm package..."
	$__process = RPM-Create-Archive `
		"${_src}" `
		"${_dest}" `
		"${env:PROJECT_SKU}" `
		"${_target_arch}"
	if ($__process -ne 0) {
		OS-Print-Status error "package failed."
		return 1
	}

	# report status
	return 0
}
