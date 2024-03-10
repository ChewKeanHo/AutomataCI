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
. "${env:LIBS_AUTOMATACI}\services\io\sync.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\msi.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!`n"
	return
}




function SUBROUTINE-Package-MSI {
	param(
		[string]$__line
	)


	# initialize libraries from scratch
	$null = . "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\services\compilers\msi.ps1"


	# parse input
	$__list = $__line -split "\|"
	$__target = $__list[0]
	$__dest = $__list[1]
	$__log = $__list[2]

	$__subject = Split-Path -Leaf -Path "${__log}"
	$__subject = FS-Extension-Remove "${__subject}" "*"
	$__subject = $__subject -replace "^msi-wxs_", ""

	$__arch = $__subject -replace '.*windows-',''
	$__arch = $__arch -replace '_.*',''

	$__lang = $__subject -split "_"
	$__lang = $__lang[2]


	# execute
	$null = I18N-Package "${__subject}"
	$($___process = MSI-Compile "${__target}" "${__arch}" "${__lang}") *> "${__log}"
	if ($___process -ne 0) {
		$null = I18N-Package-Failed
		return 1
	}

	$__target = FS-Extension-Replace "${__target}" ".wxs" ".msi"
	$null = I18N-Export "${__target}"
	if (-not (Test-Path "${__target}")) {
		$null = I18N-Export-Missing "${__subject}"
		return 1
	}

	$___process = FS-Copy-File `
		"${__target}" `
		"${__dest}\$(Split-Path -Leaf -Path "${__target}")"
	if ($___process -ne 0) {
		$null = I18N-Export-Failed "${__subject}"
		return 1
	}


	# report status
	return 0
}




function PACKAGE-Run-MSI {
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
	$null = I18N-Check-Availability "MSI"
	$___process = MSI-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 0
	}


	# prepare workspace and required values
	$null = I18N-Create-Package "MSI"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\msi_${_src}"
	$null = I18N-Remake "${_src}"
	$___process = FS-Remake-Directory "${_src}"
	if ($___process -ne 0) {
		$null = I18N-Remake-Failed
		return 1
	}

	$__control_directory = "${_src}\.automataCI"
	$null = I18N-Remake "${__control_directory}"
	$___process = FS-Remake-Directory "${__control_directory}"
	if ($___process -ne 0) {
		$null = I18N-Remake-Failed
		return 1
	}

	$__parallel_control = "${__control_directory}\control-parallel.txt"
	$null = FS-Remove-Silently "${__parallel_control}"


	# copy all complimentary files to the workspace
	$null = I18N-Check-Function "PACKAGE-Assemble-MSI-Content"
	$___process = OS-Is-Command-Available "PACKAGE-Assemble-MSI-Content"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$null = I18N-Assemble-Package
	$___process = PACKAGE-Assemble-MSI-Content `
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
	foreach ($__recipe in (Get-ChildItem -Path "${_src}" -Filter *.wxs)) {
		$___process = FS-Is-File "${__recipe}"
		if ($___process -ne 0) {
			continue
		}


		# register for packaging in parallel
		$null = I18N-Sync-Register "${__recipe}"
		$__log = Split-Path -Leaf -Path "${__recipe}"
		$__log = FS-Extension-Remove "${__log}" "*"
		$__log = "${__control_directory}\msi-wxs_${__log}.log"
		$___process = FS-Append-File "${__parallel_control}" @"
${__recipe}|${_dest}|${__log}
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	$null = I18N-Sync-Run
	$___process = FS-Is-File "${__parallel_control}"
	if ($___process -eq 0) {
		$___process = SYNC-Exec-Parallel `
			${function:SUBROUTINE-Package-MSI}.ToString() `
			"${__parallel_control}" `
			"${__control_directory}" `
			"$([System.Environment]::ProcessorCount)"
	} else {
		$null = I18N-Sync-Run-Skipped
		$___process = 0
	}

	foreach ($__log in (Get-ChildItem -Path "${__control_directory}" -Filter *.log)) {
		$null = I18N-Sync-Report-Log "${__log}"
		foreach ($__line in (Get-Content "${__log}")) {
			$null = I18N-Status-Print plain "${__line}"
		}
		$null = I18N-Newline
	}


	# report status
	if ($___process -ne 0) {
		$null = I18N-Sync-Failed
		return 1
	}

	return 0
}
