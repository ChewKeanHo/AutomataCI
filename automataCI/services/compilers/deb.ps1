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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\ar.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\checksum\md5.ps1"




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
	$null = Set-Location "${__directory}\control"
	$__process = TAR-Create-XZ "..\control.tar.xz" "*"
	$null = Set-Location $__current_path
	if ($__process -ne 0) {
		$null = Remove-Variable -Name __current_path
		return 1
	}


	# package data
	$null = Set-Location "${__directory}\data"
	$__process = TAR-Create-XZ "..\data.tar.xz" "*"
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
	$__file = "package.deb"
	$__process = AR-Create "${__file}" "debian-binary control.tar.xz data.tar.xz"
	$null = Set-Location $__current_path
	if ($__process -ne 0) {
		$null = Remove-Variable -Name __current_path
		return 1
	}


	# move to destination
	$null = Set-Location "${__directory}"
	$null = FS-Remove-Silently "${__destination}"
	$__process = FS-Move "${__file}" "${__destination}"


	# return back to current path
	$null = Set-Location -Path $__current_path
	$null = Remove-Variable -Name __current_path


	# report status
	return $__process
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
	if ($__is_native -eq "true") {
		$__location = "${__directory}\data\usr\share\doc\${__sku}\changelog.gz"
	}


	# create housing directory path
	$null = FS-Make-Housing-Directory "${__location}"
	$null = FS-Remove-Silently "${__location}"


	# copy processed file to the target location
	$__process = FS-Copy-File "${__filepath}" "${__location}"


	# report status
	return $__process
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
	$null = FS-Remove-Silently "${__location}"
	$null = FS-Make-Housing-Directory "${__location}"


	# checksum each file
	foreach ($__file in (Get-ChildItem -Path "${__directory}\data" -File -Recurse)) {
		$__checksum = MD5-Checksum-File $__file.FullName
		$__path = $__file.FullName -replace [regex]::Escape("${__directory}\data\"), ""
		$__path = $__path -replace "\\", "/"
		$__process = FS-Append-File "${__location}" "${__checksum} ${__path}"
		if ($__process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function DEB-Create-Control {
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
	$__arch = DEB-Get-Architecture "${__os}" "${__arch}"
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




function DEB-Create-Source-List {
	param(
		[string]$__is_simulated,
		[string]$__directory,
		[string]$__gpg_id,
		[string]$__url,
		[string]$__codename,
		[string]$__distribution,
		[string]$__sku
	)


	# validate input
	if ([string]::IsNullOrEmpty(${__directory}) -or
		(-not (Test-Path "${__directory}" -PathType Container)) -or
		([string]::IsNullOrEmpty(${__gpg_id}) -and
			[string]::IsNullOrEmpty(${__is_simulated})) -or
		[string]::IsNullOrEmpty(${__url}) -or
		[string]::IsNullOrEmpty(${__codename}) -or
		[string]::IsNullOrEmpty(${__distribution}) -or
		[string]::IsNullOrEmpty(${__sku})) {
		return 1
	}


	# execute
	$__url = "${__url}/deb"
	$__url = $__url -replace "//deb", "/deb"
	$__key = "usr\local\share\keyrings\${__sku}-keyring.gpg"
	$__filename = "${__directory}\data\etc\apt\sources.list.d\${__sku}.list"

	$__process = FS-Is-File "${__filename}"
	if ($__process -eq 0) {
		return 10
	}

	$__process = FS-Is-File "${__directory}\data\${__key}"
	if ($__process -eq 0) {
		return 1
	}

	$null = FS-Make-Housing-Directory "${__filename}"
	$__process = FS-Write-File "${__filename}" @"
# WARNING: AUTO-GENERATED - DO NOT EDIT!
deb [signed-by=/${__key}] ${__url} ${__codename} ${__distribution}
"@
	if ($__process -ne 0) {
		return 1
	}

	$null = FS-Make-Housing-Directory "${__directory}\data\${__key}"
	if (-not [string]::IsNullOrEmpty($__is_simulated)) {
		$__process = FS-Write-File "${__directory}\data\${__key}" ""
	} else {
		$__process = GPG-Export-Public-Keyring `
			"${__directory}\data\${__key}" `
			"${__gpg_id}"
	}


	# report status
	if ($__process -ne 0) {
		return 1
	}

	return 0
}




function DEB-Get-Architecture {
	param (
		[string]$___os,
		[string]$___arch
	)


	# validate input
	if ([string]::IsNullOrEmpty($___os) -or [string]::IsNullOrEmpty($___arch)) {
		return ""
	}


	# process os
	switch ($___os) {
	"dragonfly" {
		$___output="dragonflybsd"
	} default {
		$___output="${___os}"
	}}


	# process arch
	switch ($___arch) {
	{ $_ -in "386", "i386", "486", "i486", "586", "i586", "686", "i686" } {
		$___output = "${___output}-i386"
	} "mipsle" {
		$___output = "${___output}-mipsel"
	} "mipsr6le" {
		$___output = "${___output}-mipsr6el"
	} "mips32le" {
		$___output = "${___output}-mips32el"
	} "mips32r6le" {
		$___output = "${___output}-mips32r6el"
	} "mips64le" {
		$___output = "${___output}-mips64el"
	} "mips64r6le" {
		$___output = "${___output}-mips64r6el"
	} "powerpcle" {
		$___output = "${___output}-powerpcel"
	} "ppc64le" {
		$___output = "${___output}-ppc64el"
	} default {
		$___output = "${___output}-${___arch}"
	}}


	# report status
	return STRINGS-To-Lowercase "${___output}"
}




function DEB-Is-Available {
	param(
		[string]$__os,
		[string]$__arch
	)

	if ([string]::IsNullOrEmpty($__os) -or [string]::IsNullOrEmpty($__arch)) {
		return 1
	}


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


	# check compatible target os
	switch ($__os) {
	{ $_ -in 'windows', 'darwin' } {
		return 2
	} Default {
		# accepted
	}}


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




function DEB-Is-Valid {
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
	if ($(${__target} -split '\.')[-1] -eq "deb") {
		return 0
	}


	# report status
	return 1
}
