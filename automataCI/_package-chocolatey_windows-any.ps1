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
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\chocolatey.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-shasum.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!`n"
	return
}




function PACKAGE-Run-CHOCOLATEY {
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
	$null = I18N-Status-Print-Check-Availability "ZIP"
	$___process = ZIP-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Incompatible "ZIP"
		return 1
	}


	# prepare workspace and required values
	$null = I18N-Status-Print-Package-Create "CHOCOLATEY"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\choco_${_src}"
	$null = I18N-Status-Print-Package-Workspace-Remake "${_src}"
	$___process = FS-Remake-Directory "${_src}"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}


	# copy all complimentary files to the workspace
	$cmd = "PACKAGE-Assemble-CHOCOLATEY-Content"
	$null = I18N-Status-Print-Package-Assembler-Check "$cmd"
	$___process = OS-Is-Command-Available "PACKAGE-Assemble-CHOCOLATEY-Content"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Package-Check-Failed
		return 1
	}

	$null = I18N-Status-Print-Package-Assembler-Exec
	$___process = PACKAGE-Assemble-CHOCOLATEY-Content `
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


	# check nuspec is available
	$null = I18N-Status-Print-File-Check-Exists ".nuspec metadata"
	$__name = ""
	foreach ($__file in (Get-ChildItem -File -Path "${_src}\*.nuspec")) {
		if ($(STRINGS-Is-Empty "${__name}") -ne 0) {
			$null = I18N-Status-Print-File-Check-Failed
			return 1
		}

		$__name = $__file.Name -replace '\.nuspec.*$', ''
	}

	if ($(STRINGS-Is-Empty "${__name}") -eq 0) {
		$null = I18N-Status-Print-File-Check-Failed
		return 1
	}


	# archive the assembled payload
	$__name = "${__name}-chocolatey_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}.nupkg"
	$__name = "${_dest}\${__name}"
	$null = I18N-Status-Print-File-Archive "${__name}"
	$___process = CHOCOLATEY-Archive "${__name}" "${_src}"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-File-Archive-Failed
		return 1
	}


	# test the package
	$null = I18N-Status-Print-Package-Testing "${__name}"
	$___process = CHOCOLATEY-Is-Available
	if ($___process -eq 0) {
		$___process = CHOCOLATEY-Test "${__name}"
		if ($___process -ne 0) {
			$null = I18N-Status-Print-Package-Testing-Failed
			return 1
		}
	} else {
		$null = I18N-Status-Print-Package-Testing-Skipped
	}


	# report status
	return 0
}
