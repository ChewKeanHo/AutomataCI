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
. "${env:LIBS_AUTOMATACI}\services\compilers\python.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return
}




function PACKAGE-Run-PYPI {
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
	if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
		$null = PYTHON-Activate-VENV
	}

	$null = I18N-Status-Print-Check-Availability "PYPI"
	$__process = PYPI-Is-Available
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "PYPI"
		return 0
	}


	# prepare workspace and required values
	$null = I18N-Status-Print-Package-Create "PYPI"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\pypi_${_src}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\pypi_${_src}"
	$null = I18N-Status-Print-Package-Workspace-Remake "${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}

	$null = I18N-Status-Print-File-Check-Exists "${_target_path}"
	$___process = FS-Is-Directory "${_target_path}"
	if ($___process -eq 0) {
		$null = I18N-Status-Print-File-Check-Failed
		return 1
	}


	# copy all complimentary files to the workspace
	$cmd = "PACKAGE-Assemble-PYPI-Content"
	$null = I18N-Status-Print-Package-Assembler-Check "$cmd"
	$___process = OS-Is-Command-Available "$cmd"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Package-Check-Failed
		return 1
	}

	$___process = PACKAGE-Assemble-PYPI-Content `
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


	# generate required files
	$null = I18N-Status-Print-File-Create "pyproject.toml"
	$___process = PYPI-Create-Config `
		"${_src}" `
		"${env:PROJECT_NAME}" `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_PITCH}" `
		"${env:PROJECT_PYPI_README}" `
		"${env:PROJECT_PYPI_README_MIME}" `
		"${env:PROJECT_LICENSE}"
	switch ($___process) {
	2 {
		$null = I18N-Status-Print-File-Injected
	} 0 {
		# accepted
	} default {
		$null = I18N-Status-Print-File-Create-Failed
		return 1
	}}


	# archive the assembled payload
	$null = I18N-Status-Print-Package-Exec "${_target_path}"
	$null = FS-Make-Directory "${_target_path}"
	$___process = PYPI-Create-Archive "${_src}" "${_target_path}"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Package-Exec-Failed "${_target_path}"
		return 1
	}


	# report status
	return 0
}
