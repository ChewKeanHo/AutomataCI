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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\disk.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\tar.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\ar.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\checksum\md5.ps1"




function DEB-Is-Available {
	param(
		[string]$__os,
		[string]$__arch
	)

	if ([string]::IsNullOrEmpty($__os) -or [string]::IsNullOrEmpty($__arch)) {
		return 1
	}

	# check compatible target os
	switch ($__os) {
	windows {
		return 2
	} darwin {
		return 2
	} Default {
		Break
	}}

	# check compatible target cpu architecture
	switch ($__arch) {
	any {
		return 3
	} Default {
		Break
	}}

	# validate dependencies
	$__process = MD5-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = TAR-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = AR-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = DISK-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function DEB-Is-Valid {
	param (
		[string]__target
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		(Test-Path "${__target}" -PathType Container) -or
		(-not (Test-Path "${__target}"))) {
		return 1
	}

	# execute
	if ($(${__target} -split '\.')[-1] -eq "deb") {
		return 0
	}

	# report status
	return 1
}




function DEB-Create-Checksum {
	param (
		[string]$__directory
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path "${__directory}" -PathType Container))) {
		return 1
	}

	# check if is the document already injected
	$__location = "${__directory}\control\md5sums"
	if (Test-Path -Path "${__location}") {
		return 2
	}

	# create housing directory path
	$null = FS-Make-Housing-Directory "${__location}"

	# checksum each file
	foreach ($__file in (Get-ChildItem -Path "${__directory}/data" -File)) {
		$__checksum = MD5-Checksum-File $__file.FullName
		$__path = $__file.FullName -replace [regex]::Escape("${__directory}/data/"), ""
		FS-Append-File "${__location}" "${__checksum} ${__path}"
	}

	# report status
	return 0
}




function DEB-Create-Changelog {
	param (
		[string]$__directory,
		[string]$__filepath,
		[string]$__is_native,
		[string]$__sku
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		[string]::IsNullOrEmpty($__filepath) -or
		(-not (Test-Path $__filepath)) -or
		[string]::IsNullOrEmpty($__is_native) -or
		[string]::IsNullOrEmpty($__sku)) {
		return 1
	}

	# check if the document has already injected
	$__location = "${__directory}\data\usr\local\share\doc\${__sku}\changelog.gz"
	if (Test-Path -Path "${__location}") {
		return 2
	}

	if ($__is_native == "true") {
		$__location = "${__directory}\data\usr\share\doc\${__sku}\changelog.gz"
		if (Test-Path -Path "${__location}") {
			return 2
		}
	}

	# create housing directory path
	$null = FS-Make-Housing-Directory "${__location}"

	# copy processed file to the target location
	$__process = FS-Copy-File "${__filepath}" "${__location}"

	# report status
	return $__process
}




function DEB-Create-Control {
	param (
		[string]$__directory,
		[string]$__resources,
		[string]$__sku,
		[string]$__version,
		[string]$__arch,
		[string]$__name,
		[string]$__email,
		[string]$__website,
		[string]$__pitch,
		[string]$__priority,
		[string]$__section
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		[string]::IsNullOrEmpty($__resources) -or
		(-not (Test-Path $__resources -PathType Container)) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__version) -or
		[string]::IsNullOrEmpty($__arch) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website) -or
		[string]::IsNullOrEmpty($__pitch) -or
		[string]::IsNullOrEmpty($__priority) -or
		[string]::IsNullOrEmpty($__section)) {
		return 1
	}

	switch (${__priority}) {
	required {
		break
	} important {
		break
	} standard {
		break
	} optional {
		break
	} extra {
		break
	} Default {
		return 1
	}}

	# check if is the document already injected
	$__location = "${__directory}\control\control"
	if (Test-Path -Path "${__location}") {
		return 2
	}

	# create housing directory path
	$null = FS-Make-Housing-Directory "${__location}"

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
	Get-Content -Path "${__resources}/packages/DESCRIPTION.txt" | ForEach-Object {
		$__line = $_
		if (![string]::IsNullOrEmpty($__line) -and
			($__line -eq $__line -replace "#.*$")) {
			continue
		}

		if ([string]::IsNullOrEmpty($__line)) {
			$__line = " ."
		} else {
			$__line = " ${__line}"
		}

		$null = FS-Append-File $__location $__line
	}

	# report status
	return 0
}




function DEB-Create-Archive {
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
	Set-Location "${__directory}\control"
	$__process = TAR-Create-XZ "..\control.tar.xz" "*"
	if ($__process -ne 0) {
		Set-Location $__current_path
		Remove-Variable -Name __current_path
		return 1
	}

	# package data
	Set-Location "${__directory}\data"
	$__process = TAR-Create-XZ "..\data.tar.xz" ".\[a-z]*"
	if ($__process -ne 0) {
		Set-Location $__current_path
		Remove-Variable -Name __current_path
		return 1
	}

	# generate debian-binary
	Set-Location "${__directory}"
	$__process = FS-Write-File "${__directory}\debian-binary" "2.0`n"
	if ($__process -ne 0) {
		Set-Location $__current_path
		Remove-Variable -Name __current_path
		return 1
	}

	# archive into deb
	$__file = "package.deb"
	$__process = AR-Create "${__file}" "debian-binary control.tar.xz data.tar.xz"
	if ($__process -ne 0) {
		Set-Location $__current_path
		Remove-Variable -Name __current_path
		return 1
	}

	# move to destination
	$null = FS-Remove-Silently "${__destination}"
	$__process = FS-Move "${__file}" "${__destination}"

	# return back to current path
	Set-Location -Path $__current_path
	Remove-Variable -Name __current_path

	# report status
	return $__process
}
