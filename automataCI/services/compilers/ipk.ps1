# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\disk.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\tar.ps1"




function IPK-Create-Archive {
	param (
		[string]$__directory,
		[string]$__destination
	)


	# validate input
	if ([string]::IsNullOrEmpty(${__directory}) -or
		(-not (Test-Path "${__directory}" -PathType Container)) -or
		(-not (Test-Path "${__directory}\control" -PathType Container)) -or
		(-not (Test-Path "${__directory}\data" -PathType Container)) -or
		(-not (Test-Path "${__directory}\control\control"))) {
		return 1
	}


	# change directory into workspace
	$__current_path = Get-Location


	# package control
	$null = Set-Location "${__directory}\control"
	$__process = TAR-Create-GZ "..\control.tar.gz" "*"
	$null = Set-Location $__current_path
	if ($__process -ne 0) {
		$null = Remove-Variable -Name __current_path
		return 1
	}


	# package data
	$null = Set-Location "${__directory}\data"
	$__process = TAR-Create-GZ "..\data.tar.gz" "*"
	$null = Set-Location $__current_path
	if ($__process -ne 0) {
		$null = Remove-Variable -Name __current_path
		return 1
	}


	# generate debian-binary
	$null = Set-Location "${__directory}"
	$__process = FS-Write-File ".\debian-binary" "2.0`n"
	$null = Set-Location $__current_path
	if ($__process -ne 0) {
		$null = Remove-Variable -Name __current_path
		return 1
	}


	# archive into deb
	$null = Set-Location "${__directory}"
	$__file = "package.ipk"
	$__process = TAR-Create-GZ "${__file}" "debian-binary control.tar.gz data.tar.gz"
	$null = Set-Location $__current_path
	if ($__process -ne 0) {
		$null = Remove-Variable -Name __current_path
		return 1
	}


	# move to destination
	$null = Set-Location "${__directory}"
	$null = FS-Remove-Silently "${__destination}"
	$__process = FS-Move "${__file}.gz" "${__destination}"


	# return back to current path
	$null = Set-Location -Path $__current_path
	$null = Remove-Variable -Name __current_path


	# report status
	return $__process
}




function IPK-Create-Control {
	param (
		[string]$__directory,
		[string]$__resources,
		[string]$__sku,
		[string]$__version,
		[string]$__arch,
		[string]$__os,
		[string]$__name,
		[string]$__email,
		[string]$__website,
		[string]$__pitch,
		[string]$__priority,
		[string]$__section,
		[string]$__description_filepath
	)


	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		[string]::IsNullOrEmpty($__resources) -or
		(-not (Test-Path $__resources -PathType Container)) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__version) -or
		[string]::IsNullOrEmpty($__arch) -or
		[string]::IsNullOrEmpty($__os) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website) -or
		[string]::IsNullOrEmpty($__pitch) -or
		[string]::IsNullOrEmpty($__priority) -or
		[string]::IsNullOrEmpty($__section)) {
		return 1
	}

	switch (${__priority}) {
	{ $_ -in "required", "important", "standard", "optional", "extra" } {
		break
	} Default {
		return 1
	}}


	# check if is the document already injected
	$__arch = IPK-Get-Architecture "${__os}" "${__arch}"
	$__location = "${__directory}\control\control"
	$null = FS-Make-Housing-Directory "${__location}"
	$null = FS-Remove-Silently "${__location}"


	# generate control file
	$__size = DISK-Calculate-Size "${__directory}\data"
	if ([string]::IsNullOrEmpty($__size)) {
		return 1
	}

	$null = FS-Write-File "${__location}" @"
Package: ${__sku}
Version: ${__version}
Architecture: ${__arch}
Maintainer: ${__name} <${__email}>
Installed-Size: ${__size}
Section: ${__section}
Priority: ${__priority}
Homepage: ${__website}
Description: ${__pitch}
"@


	# append description data file
	if ((-not [string]::IsNullOrEmpty($__description_filepath)) -and
		(Test-Path -Path "${__description_filepath}")) {
		foreach ($__line in (Get-Content -Path "${__description_filepath}")) {
			if ((-not [string]::IsNullOrEmpty($__line)) -and
				[string]::IsNullOrEmpty($__line -replace "#.*$")) {
				continue
			}

			if ([string]::IsNullOrEmpty($__line)) {
				$__line = " ."
			} else {
				$__line = " ${__line}"
			}

			$null = FS-Append-File $__location $__line
		}
	}


	# report status
	return 0
}




function IPK-Get-Architecture {
	param (
		[string]$___os,
		[string]$___arch
	)


	# validate input
	if ([string]::IsNullOrEmpty($___os) -or [string]::IsNullOrEmpty($___arch)) {
		return ""
	}


	# report status
	return STRINGS-To-Lowercase "${___os}-${___arch}"
}




function IPK-Is-Available {
	param(
		[string]$__os,
		[string]$__arch
	)

	if ([string]::IsNullOrEmpty($__os) -or [string]::IsNullOrEmpty($__arch)) {
		return 1
	}


	# validate dependencies
	$__process = TAR-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = DISK-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# check compatible target cpu architecture
	switch ($__arch) {
	{ $_ -in 'any' } {
		return 3
	} Default {
		# accepted
	}}


	# report status
	return 0
}




function IPK-Is-Valid {
	param (
		[string]$__target
	)


	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		(Test-Path "${__target}" -PathType Container) -or
		(-not (Test-Path "${__target}"))) {
		return 1
	}


	# execute
	if ($(${__target} -split '\.')[-1] -eq "ipk") {
		return 0
	}


	# report status
	return 1
}
