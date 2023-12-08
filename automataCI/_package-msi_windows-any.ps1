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
. "${env:LIBS_AUTOMATACI}\services\io\sync.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\printer.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




function SUBROUTINE-Package-MSI {
	param(
		[string]$__line
	)


	# initialize libraries from scratch
	$null = . "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\services\compilers\msi.ps1"

	$null = . "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"


	# parse input
	$__list = $__line -split "\|"
	$__target = $__list[0]
	$__dest = $__list[1]
	$__log = $__list[2]

	$__subject = Split-Path -Leaf -Path "${__log}"
	$__subject = FS-Extension-Remove "${__subject}" "*"

	$__arch = $__subject -replace '.*windows-',''
	$__arch = $__arch -replace '_.*',''

	$__lang = $__subject -split "_"
	$__lang = $__lang[1]


	# execute
	$null = I18N-Status-Print-Package-Exec "${__subject}"
	$($__process = MSI-Compile "${__target}" "${__arch}" "${__lang}") *> "${__log}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Exec-Failed "${__subject}"
		return 1
	}

	$__target = FS-Extension-Replace "${__target}" ".wxs" ".msi"
	$null = I18N-Status-Print-Package-Export "${__target}"
	if (-not (Test-Path "${__target}")) {
		$null = I18N-Status-Print-Package-Export-Failed-Missing "${__subject}"
		return 1
	}

	$__process = FS-Copy-File `
		"${__target}" `
		"${__dest}\$(Split-Path -Leaf -Path "${__target}")"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Export-Failed "${__subject}"
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


	# NOTE: temporary disables MSI since we do not have a Windows OS to
	#       operate and GitHub Actions' Windows image is no longer usable.
	return 0


	# validate input
	$null = I18N-Status-Print-MSI-Check-Availability
	$__process = MSI-Is-Available
	if ($__process -ne 0) {
		$null = I18N-Status-Print-MSI-Check-Availability-Failed
		return 0
	}


	# prepare workspace and required values
	$null = I18N-Status-Print-Package-Create "MSI"
	$_src = "${_target_filename}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}"
	$_src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\msi_${_src}"
	$null = I18N-Status-Print-Package-Workspace-Remake "${_src}"
	$__process = FS-Remake-Directory "${_src}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}

	$__control_directory = "${_src}\.automataCI"
	$null = I18N-Status-Print-Package-Workspace-Remake-Control "${__control_directory}"
	$null = FS-Remake-Directory "${__control_directory}"
	if (-not (Test-Path -PathType Container -Path "${__control_directory}")) {
		$null = I18N-Status-Print-Package-Remake-Failed
		return 1
	}

	$__parallel_control = "${__control_directory}\control-parallel.txt"
	$null = FS-Remove-Silently "${__parallel_control}"


	# copy all complimentary files to the workspace
	$null = I18N-Status-Print-Package-Assembler-Check "PACKAGE-Assemble-MSI-Content"
	$__process = OS-Is-Command-Available "PACKAGE-Assemble-MSI-Content"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Check-Failed
		return 1
	}

	$null = I18N-Status-Print-Package-Assembler-Exec
	$__process = PACKAGE-Assemble-MSI-Content `
		"${_target}" `
		"${_src}" `
		"${_target_filename}" `
		"${_target_os}" `
		"${_target_arch}"
	switch ($__process) {
	10 {
		$null = FS-Remove-Silently "${_src}"
		$null = I18N-Status-Print-Package-Assembler-Exec-Skipped
		return 0
	} 0 {
		# accepted
	} Default {
		$null = I18N-Status-Print-Package-Assembler-Exec-Failed
		return 1
	}}


	# archive the assembled payload
	$null = FS-Remake-Directory "${__control_directory}"
	foreach ($__recipe in (Get-ChildItem -Path "${_src}" -Filter "*.wxs")) {
		$__process = FS-Is-File "${__recipe}"
		if ($__process -ne 0) {
			continue
		}

		$null = I18N-Status-Print-Package-Parallelism-Register "${__recipe}"
		$__log = Split-Path -Leaf -Path "${__recipe}"
		$__log = FS-Extension-Remove "${__log}" "*"
		$__log = "${__control_directory}\msi-wxs_${__log}.log"
		$__process = FS-Append-File "${__parallel_control}" @"
${__recipe}|${_dest}|${__log}
"@
		if ($__process -ne 0) {
			return 1
		}
	}

	$null = I18N-Status-Print-Package-Parallelism-Run
	if (Test-Path "${__parallel_control}") {
		$__process = SYNC-Parallel-Exec `
			${function:SUBROUTINE-Package-MSI}.ToString() `
			"${__parallel_control}" `
			"${__control_directory}" `
			"$([System.Environment]::ProcessorCount)"
		if ($__process -ne 0) {
			$null = I18N-Status-Print-Package-Parallelism-Run-Failed
			return 1
		}
	} else {
		$null = I18N-Status-Print-Package-Parallelism-Run-Skipped
	}

	foreach ($__log in (Get-ChildItem -Path "${__control_directory}" -Filter *.log)) {
		$null = I18N-Status-Print-Package-Parallelism-Log "${__log}"
		foreach ($__line in (Get-Content "${__control_directory}\${__log}")) {
			$null = I18N-Status-Print-Plain "${__line}"
		}
		$null = I18N-Status-Print-Newline
	}


	# report status
	return 0
}