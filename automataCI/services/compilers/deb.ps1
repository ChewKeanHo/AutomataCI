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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\disk.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\ar.ps1"
. "${env:LIBS_AUTOMATACI}\services\crypto\gpg.ps1"
. "${env:LIBS_AUTOMATACI}\services\checksum\md5.ps1"




function DEB-Create-Archive {
	param (
		[string]$___directory,
		[string]$___destination
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___directory}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}/control"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}/data"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory}/control/control"
	if ($___process -ne 0) {
		return 1
	}


	# change directory into workspace
	$___current_path = Get-Location


	# package control
	$null = Set-Location "${___directory}\control"
	$___process = TAR-Create-XZ "..\control.tar.xz" "*"
	if ($___process -ne 0) {
		$null = Set-Location $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# package data
	$null = Set-Location "${___directory}\data"
	$___process = TAR-Create-XZ "..\data.tar.xz" "*"
	if ($___process -ne 0) {
		$null = Set-Location $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# generate debian-binary
	$null = Set-Location "${___directory}"
	$___process = FS-Write-File ".\debian-binary" "2.0`n"
	if ($___process -ne 0) {
		$null = Set-Location -Path $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# archive into deb
	$___file = "package.deb"
	$___process = AR-Create "${___file}" "debian-binary control.tar.xz data.tar.xz"
	if ($___process -ne 0) {
		$null = Set-Location -Path $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# move to destination
	$null = FS-Remove-Silently "${___destination}"
	$___process = FS-Move "${___file}" "${___destination}"


	# return back to current path
	$null = Set-Location -Path $___current_path
	$null = Remove-Variable -Name ___current_path


	# report status
	if ($___process -ne 0) {
		return 1
	}

	return 0
}




function DEB-Create-Changelog {
	param (
		[string]$___location,
		[string]$___filepath,
		[string]$___sku
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___location}") -eq 0) -or
		($(STRINGS-Is-Empty "${___filepath}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___filepath}"
	if ($___process -ne 0) {
		return 1
	}


	# create housing directory path
	$null = FS-Make-Housing-Directory "${___location}"
	$null = FS-Remove-Silently "${___location}"


	# copy processed file to the target location
	$___process = FS-Copy-File "${___filepath}" "${___location}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DEB-Create-Checksum {
	param (
		[string]$___directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___directory}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}


	# check if is the document already injected
	$___location = "${___directory}\control\md5sums"
	$null = FS-Remove-Silently "${___location}"
	$null = FS-Make-Housing-Directory "${___location}"


	# checksum each file
	foreach ($___line in (Get-ChildItem -Path "${___directory}\data" -File -Recurse)) {
		$___checksum = MD5-Checksum-From-File "${___line}"
		$___path = "${___line}" -replace [regex]::Escape("${___directory}\data\"), ""
		$___path = $___path -replace "\\", "/"
		$___process = FS-Append-File "${___location}" "${___checksum} ${___path}"
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function DEB-Create-Control {
	param (
		[string]$___directory,
		[string]$___resources,
		[string]$___sku,
		[string]$___version,
		[string]$___arch,
		[string]$___os,
		[string]$___name,
		[string]$___email,
		[string]$___website,
		[string]$___pitch,
		[string]$___priority,
		[string]$___section,
		[string]$___description_filepath
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___resources}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___email}") -eq 0) -or
		($(STRINGS-Is-Empty "${___website}") -eq 0) -or
		($(STRINGS-Is-Empty "${___pitch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___priority}") -eq 0) -or
		($(STRINGS-Is-Empty "${___section}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___resources}"
	if ($___process -ne 0) {
		return 1
	}

	switch (${___priority}) {
	{ $_ -in "required", "important", "standard", "optional", "extra" } {
		# accepted
	} Default {
		return 1
	}}


	# check if is the document already injected
	$___arch = DEB-Get-Architecture "${___os}" "${___arch}"
	$___location = "${___directory}\control\control"
	$null = FS-Make-Housing-Directory "${___location}"
	$null = FS-Remove-Silently "${___location}"


	# generate control file
	$___size = DISK-Calculate-Size "${___directory}\data"
	if ($(STRINGS-Is-Empty "${___size}") -eq 0) {
		return 1
	}

	$null = FS-Write-File "${___location}" @"
Package: ${___sku}
Version: ${___version}
Architecture: ${___arch}
Maintainer: ${___name} <${___email}>
Installed-Size: ${___size}
Section: ${___section}
Priority: ${___priority}
Homepage: ${___website}
Description: ${___pitch}
"@


	# append description data file
	$___process = FS-Is-File "${___description_filepath}"
	if ($___process -ne 0) {
		return 0 # report status early
	}

	foreach ($___line in (Get-Content -Path "${___description_filepath}")) {
		if (($(STRINGS-Is-Empty "${___line}") -ne 0) -and
			($(STRINGS-Is-Empty "$($___line -replace "#.*$")") -eq 0)) {
			continue
		}

		$___line = $___line -replace '#.*'
		if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
			$___line = " ."
		} else {
			$___line = " ${___line}"
		}

		$null = FS-Append-File $___location $___line
	}


	# report status
	return 0
}




function DEB-Create-Source-List {
	param(
		[string]$___directory,
		[string]$___gpg_id,
		[string]$___url,
		[string]$___codename,
		[string]$___distribution,
		[string]$___keyring
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___url}") -eq 0) -or
		($(STRINGS-Is-Empty "${___codename}") -eq 0) -or
		($(STRINGS-Is-Empty "${___distribution}") -eq 0) -or
		($(STRINGS-Is-Empty "${___keyring}") -eq 0)) {
		return 1
	}

	if (($(STRINGS-Is-Empty "${___gpg_id}") -eq 0) -and ($(OS-Is-Run-Simulated) -ne 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___url = "${___url}/deb"
	$___url = $___url -replace "//deb", "/deb"
	$___key = "usr\local\share\keyrings\${___keyring}-keyring.gpg"
	$___filename = "${___directory}\data\etc\apt\sources.list.d\${___keyring}.list"

	$___process = FS-Is-File "${___filename}"
	if ($___process -eq 0) {
		return 10
	}

	$___process = FS-Is-File "${___directory}\data\${___key}"
	if ($___process -eq 0) {
		return 1
	}

	$null = FS-Make-Housing-Directory "${___filename}"
	$___process = FS-Write-File "${___filename}" @"
# WARNING: AUTO-GENERATED - DO NOT EDIT!
deb [signed-by=/${___key}] ${___url} ${___codename} ${___distribution}
"@
	if ($___process -ne 0) {
		return 1
	}

	$null = FS-Make-Housing-Directory "${___directory}\data\${___key}"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$___process = FS-Write-File "${___directory}\data\${___key}" ""
	} else {
		$___process = GPG-Export-Public-Keyring `
			"${___directory}\data\${___key}" `
			"${___gpg_id}"
	}
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DEB-Get-Architecture {
	param (
		[string]$___os,
		[string]$___arch
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0)) {
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
		[string]$___os,
		[string]$___arch
	)

	if (($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0)) {
		return 1
	}


	# validate dependencies
	$___process = MD5-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = TAR-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = AR-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = DISK-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# check compatible target os
	switch ($___os) {
	{ $_ -in 'windows', 'darwin' } {
		return 2
	} Default {
		# accepted
	}}


	# check compatible target cpu architecture
	switch ($___arch) {
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
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	if ($(${___target} -split '\.')[-1] -eq "deb") {
		return 0
	}


	# report status
	return 1
}
