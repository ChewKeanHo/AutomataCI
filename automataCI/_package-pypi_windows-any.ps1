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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\python.ps1"




function PACKAGE-Run-PyPi {
	param (
		[string]$__target,
		[string]$__target_filename,
		[string]$__target_sku,
		[string]$__target_os,
		[string]$__target_arch
	)

	if ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON})) {
		$null = PYTHON-Activate-VENV
	}

	$__process = PYPI-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status warning "PyPi is incompatible or not available. Skipping."
		return 0
	}

	$__process = FS-Is-Target-A-Source "${__target}"
	if ($__process -eq 0) {
		$__src = "pypi-src_${__target_filename}_${__target_os}-${__target_arch}"
	} else {
		$__src = "pypi_${__target_filename}_${__target_os}-${__target_arch}"
	}
	$__src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${__src}"
	$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
	OS-Print-Status info "Creating PyPi source code package..."
	OS-Print-Status info "remaking workspace directory ${__src}"
	$__process = FS-Remake-Directory "${__src}"
	if ($__process -ne 0) {
		OS-Print-Status error "remake failed."
		return 1
	}

	$__target_path = "${__dest}\pypi_${__target_sku}_${__target_os}-${__target_arch}"
	OS-Print-Status info "checking output file existence..."
	if (Test-Path -Path "${__target_path}") {
		OS-Print-Status error "check failed - output exists!"
		return 1
	}

	# copy all complimentary files to the workspace
	OS-Print-Status info "assembling package files..."
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-PyPi-Content"
	if ($__process -ne 0) {
		OS-Print-Status error "missing PACKAGE-Assemble-PyPi-Content function."
		return 1
	}
	$__process = PACKAGE-Assemble-PyPi-Content `
			${__target} `
			${__src} `
			${__target_filename} `
			${__target_os} `
			${__target_arch}
	if ($__process -eq 10) {
		$null = FS-Remove-Silently ${__src}
		OS-Print-Status warning "packaging is not required. Skipping process."
		return 0
	} else if ($__process -ne 0) {
		OS-Print-Status error "assembly failed."
		return 1
	}

	# generate required files
	OS-Print-Status info "creating setup.py file..."
	$__process = PYPI-Create-Setup-PY `
		${__src} `
		${env:PROJECT_NAME} `
		${env:PROJECT_VERSION} `
		${env:PROJECT_CONTACT_NAME} `
		${env:PROJECT_CONTACT_EMAIL} `
		${env:PROJECT_CONTACT_WEBSITE} `
		${env:PROJECT_PITCH} `
		"${env:PROJECT_PATH_ROOT}\README.md" `
		"text/markdown"
	if ($__process -eq 2) {
		OS-Print-Status info "manual injection detected."
	} else if ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	# archive the assembled payload
	OS-Print-Status info "archiving .pypi package..."
	FS-Make-Directory $__target_path
	$__process = PYPI-Create-Archive "${__src}" "${__target_path}"
	if ($__process -ne 0) {
		OS-Print-Status error "package failed."
		return 1
	}

	# report status
	return 0
}
