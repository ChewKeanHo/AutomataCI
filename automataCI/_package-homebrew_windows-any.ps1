# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\checksum\shasum.ps1"





# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!`n"
	return
}




function PACKAGE-Run-HOMEBREW {
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
	$null = I18N-Check-Availability "TAR"
	$___process = TAR-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# prepare workspace and required values
	$null = I18N-Create-Package "HOMEBREW"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_target_path = "${_dest}\${_src}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\homebrew_${_src}"
	$null = I18N-Remake "${_src}"
	$___process = FS-Remake-Directory "${_src}"
	if ($___process -ne 0) {
		$null = I18N-Remake-Failed
		return 1
	}


	# check formula.rb is available
	$null = I18N-Check "formula.rb"
	$___process = FS-Is-File "${_src}/formula.rb"
	if ($___process -eq 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# copy all complimentary files to the workspace
	$cmd = "PACKAGE-Assemble-HOMEBREW-Content"
	$null = I18N-Check-Function "$cmd"
	$___process = OS-Is-Command-Available "$cmd"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$null = I18N-Assemble-Package
	$___process = PACKAGE-Assemble-HOMEBREW-Content `
		"${_target}" `
		"${_src}" `
		"${_target_filename}" `
		"${_target_os}" `
		"${_target_arch}"
	switch ($___process) {
	10 {
		$null = I18N-Assemble-Skipped
		$null = FS-Remove-Silently "${_src}"
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Assemble-Failed
		return 1
	}}


	# archive the assembled payload
	$__current_path = Get-Location
	$null = Set-Location -Path "${_src}"
	$null = I18N-Archive "${_target_path}.tar.xz"
	$___process = TAR-Create-XZ "${_target_path}.tar.xz" "*"
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path
	if ($___process -ne 0) {
		$null = I18N-Archive-Failed
		return 1
	}


	# sha256 the package
	$null = I18N-Shasum "SHA256"
	$__shasum = SHASUM-Checksum-From-File "${_target_path}.tar.xz" "256"
	if ($(STRINGS-Is-Empty "${__shasum}") -eq 0) {
		$null = I18N-Shasum-Failed
		return 1
	}


	# update the formula.rb script
	$null = I18N-Update "formula.rb"
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

		$___process = FS-Append-File "${_target_path}.rb" "${__line}"
		if ($___process -ne 0) {
			$null = I18N-Update-Failed
			return 1
		}
	}


	# report status
	return 0
}
