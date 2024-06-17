# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\disk.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\time.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\ar.ps1"
. "${env:LIBS_AUTOMATACI}\services\crypto\gpg.ps1"
. "${env:LIBS_AUTOMATACI}\services\checksum\md5.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\unix.ps1"




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


	# to workspace directory
	$___current_path = Get-Location


	# package control
	$null = Set-Location "${___directory}\control"
	$___process = TAR-Create-XZ "${___directory}\control.tar.xz" "*"
	if ($___process -ne 0) {
		$null = Set-Location $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# package data
	$null = Set-Location "${___directory}\data"
	$___process = TAR-Create-XZ "${___directory}\data.tar.xz" "*"
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


	# checksum every items
	foreach ($___line in (Get-ChildItem -Path "${___directory}\data" -File -Recurse)) {
		$___checksum = MD5-Create-From-File "${___line}"
		$___path = "${___line}" -replace [regex]::Escape("${___directory}\data\"), ''
		$___path = $___path -replace "\\", "/"
		$___checksum = $___checksum -replace "\ .*$", ''
		$___process = FS-Append-File "${___location}" "${___checksum} ${___path}`n"
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


	# prepare workspace
	$___arch = DEB-Get-Architecture "${___os}" "${___arch}"
	$___location = "${___directory}\control\control"
	$null = FS-Make-Housing-Directory "${___location}"
	$null = FS-Remove-Silently "${___location}"


	# generate control file
	$___size = DISK-Calculate-Size-Directory-KB "${___directory}\data"
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
			($(STRINGS-Is-Empty "$($___line -replace "#.*$", '')") -eq 0)) {
			continue
		}

		$___line = $___line -replace '#.*', ''
		if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
			$___line = " ."
		} else {
			$___line = " ${___line}"
		}

		$null = FS-Append-File $___location "${___line}`n"
	}


	# report status
	return 0
}




function DEB-Create-Source-List {
	param(
		[string]$___directory,
		[string]$___gpg_id,
		[string]$___url,
		[string]$___component,
		[string]$___distribution,
		[string]$___keyring
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___url}") -eq 0) -or
		($(STRINGS-Is-Empty "${___component}") -eq 0) -or
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
	if ("$($___distribution -replace "\/.*$", '')" -eq $___distribution) {
		# it's a pool repository
		$___process = FS-Write-File "${___filename}" @"
# WARNING: AUTO-GENERATED - DO NOT EDIT!
deb [signed-by=/${___key}] ${___url} ${___distribution} ${__component}

"@
	} else {
		# it's a flat repository
		$___process = FS-Write-File "${___filename}" @"
# WARNING: AUTO-GENERATED - DO NOT EDIT!
deb [signed-by=/${___key}] ${___url} ${___distribution}

"@
	}
	if ($___process -ne 0) {
		return 1
	}

	$null = FS-Make-Housing-Directory "${___directory}\data\${___key}"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$___process = FS-Write-File "${___directory}\data\${___key}" "`n"
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


	# execute
	switch ($___os) {
	any {
		$___output = "all-"
	} linux {
		$___output = ""
	} dragonfly {
		$___output = "dragonflybsd-"
	} default {
		$___output = "${___os}-"
	}}
	$___output = "${___output}$(UNIX-Get-Arch "${___arch}")"
	if ($___output -eq "all-all") {
		$___output = "all"
	}


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

	$___process = SHASUM-Is-Available
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

	$___process = GPG-Is-Available
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




function DEB-Publish {
	param (
		[string]$___repo_directory,
		[string]$___data_directory,
		[string]$___workspace_directory,
		[string]$___target,
		[string]$___distribution,
		[string]$___component
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___repo_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___data_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___workspace_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___distribution}") -eq 0) -or
		($(STRINGS-Is-Empty "${___component}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___repo_directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___directory_unpack = "${___workspace_directory}\deb"
	$___repo_is_pool = $false
	if ("$($___distribution -replace "\/.*$", '')" -eq $___distribution) {
		# it's a pool repository
		$___repo_is_pool = $true
	} else {
		# it's a flat repository
		$___distribution = $___distribution -replace "\/.*$", ''
	}


	# unpack package control section
	$null = FS-Remake-Directory "${___directory_unpack}"
	$___process = DEB-Unpack "${___directory_unpack}" "${___target}" "control"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory_unpack}\control\control"
	if ($___process -ne 0) {
		return 1
	}


	# parse package control data
	$___value_type = "binary" # currently support this for now
	$___value_package = ""
	$___value_version = ""
	$___value_arch = ""
	$___value_maintainer = ""
	$___value_buffer = ""
	$___value_size = "$(DISK-Calculate-Size-File-Byte "${___target}")"
	$___value_sha256 = "$(SHASUM-Create-From-File "${___target}" "256")"
	$___value_sha1 = "$(SHASUM-Create-From-File "${___target}" "1")"
	$___value_md5 = "$(MD5-Create-From-File "${___target}")"
	$___value_description = ""

	foreach ($___line in (Get-Content "${___directory_unpack}/control/control")) {
		$___regex = "^.*Package:\ "
		if ("$($___line -replace $___regex, '')" -ne $___line) {
			if ($(STRINGS-Is-Empty "${___value_package}") -ne 0) {
				## invalid control file - multiple same fileds detected
				return 1
			}

			$___value_package = $___line -replace $___regex, ''
			continue
		}

		$___regex = "^.*Version:\ "
		if ("$($___line -replace $___regex, '')" -ne $___line) {
			if ($(STRINGS-Is-Empty "${___value_version}") -ne 0) {
				## invalid control file - multiple same fileds detected
				return 1
			}

			$___value_version = $___line -replace $___regex, ''
			continue
		}

		$___regex = "^.*Architecture:\ "
		if ("$($___line -replace $___regex, '')" -ne $___line) {
			if ($(STRINGS-Is-Empty "${___value_arch}") -ne 0) {
				## invalid control file - multiple same fileds detected
				return 1
			}

			$___value_arch = $___line -replace $___regex, ''
			continue
		}

		$___regex = "^.*Maintainer:\ "
		if ("$($___line -replace $___regex, '')" -ne $___line) {
			if ($(STRINGS-Is-Empty "${___value_maintainer}") -ne 0) {
				## invalid control file - multiple same fileds detected
				return 1
			}

			$___value_maintainer = $___line -replace $___regex, ''
			continue
		}

		$___regex = "^.*Description:\ "
		if ("$($___line -replace $___regex, '')" -ne $___line) {
			if ($(STRINGS-Is-Empty "${___value_description}") -ne 0) {
				## invalid control file - multiple same fileds detected
				return 1
			}

			$___value_description = $___line
			continue
		}

		if ($(STRINGS-Is-Empty "${___value_description}") -eq 0) {
			if ($(STRINGS-Is-Empty "${___value_buffer}") -ne 0) {
				$___value_buffer = "${___value_buffer}`n"
			}

			$___value_buffer = "${___value_buffer}${___line}"
		} else {
			if ($(STRINGS-Is-Empty "${___value_description}") -ne 0) {
				$___value_description = "${___value_description}`n"
			}

			$___value_description = "${___value_description}${___line}"
		}
	}


	# sanitize package metadata
	if (($(STRINGS-Is-Empty "${___value_type}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_package}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_version}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_maintainer}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_size}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_sha256}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_sha1}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_md5}") -eq 0) -or
		($(STRINGS-Is-Empty "${___value_description}") -eq 0)) {
		return 1
	}


	# process filename
	$___value_filename = "${___value_package}_${___value_version}_${___value_arch}.deb"
	if ($___repo_is_pool) {
		$___value_filename = "${___value_package}\${___value_filename}"
		$___value_filename = "$($(FS-Get-File "${___value_package}").Substring(0, 1))\${___value_filename}"
		$___value_filename = "pool\${___distribution}\${___value_filename}"
	}


	# write to package database
	$___dest = "${___value_package}_${___value_version}_${___value_arch}"
	if ($___repo_is_pool) {
		$___dest = "${___value_type}-${___value_arch}/${___dest}"
		$___dest = "${___component}\${___dest}"
		$___dest = "${___distribution}\${___dest}"
	}
	$___dest = "${___data_directory}\packages\${___dest}"
	$___process = FS-Is-File "${___dest}"
	if ($___process -eq 0) {
		return 1 # duplicated package - already registered
	}

	$null = FS-Make-Housing-Directory "${___dest}"
	$___process = FS-Write-File "${___dest}" @"
Package: ${___value_package}
Version: ${___value_version}
Architecture: ${___value_arch}
Maintainer: ${___value_maintainer}
${___value_buffer}
Filename: $($___value_filename -replace "\\", "/")
Size: ${___value_size}
SHA256: ${___value_sha256}
SHA1: ${___value_sha1}
MD5sum: ${___value_md5}
${___value_description}

"@
	if ($___process -ne 0) {
		return 1
	}


	# write to arch database
	$___dest = "${___data_directory}\arch\${___value_arch}"
	$null = FS-Make-Housing-Directory "${___dest}"
	$___process = FS-Append-File "${___dest}" "${___value_filename}`n"
	if ($___process -ne 0) {
		return 1
	}


	# export deb payload to destination
	$___dest = "${___repo_directory}\${___value_filename}"
	$___process = FS-Is-File "${___dest}"
	if ($___process -ne 0) {
		$null = FS-Make-Housing-Directory "${___dest}"
		$___process = FS-Move "${___target}" "${___dest}"
		if ($___process -ne 0) {
			return 1
		}
	} else {
		return 1 # duplicated package existence or corrupted run
	}


	# report status
	return 0
}




function DEB-Publish-Conclude {
	param (
		[string]$___repo_directory,
		[string]$___data_directory,
		[string]$___distribution,
		[string]$___arch_list,
		[string]$___component,
		[string]$___codename,
		[string]$___gpg_id
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___repo_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___data_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch_list}") -eq 0) -or
		($(STRINGS-Is-Empty "${___component}") -eq 0) -or
		($(STRINGS-Is-Empty "${___codename}") -eq 0) -or
		($(STRINGS-Is-Empty "${___gpg_id}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___repo_directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___data_directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = GPG-Is-Available "${___gpg_id}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___directory_package = "${___data_directory}\packages"
	$___repo_is_pool = $false
	if ("$($___distribution -replace "\/.*$", '')" -eq $___distribution) {
		# it's a pool repository
		$___repo_is_pool = $true
		$___repo_directory = "${___repo_directory}\dists"
	} else {
		# it's a flat repository
		$___distribution = $___distribution -replace "\/.*$", ''
	}


	# formulate arch list if empty
	if ($(STRINGS-Is-Empty "${___arch_list}") -eq 0) {
		Get-ChildItem -Path "${___data_directory}\arch" -File `
		| ForEach-Object { $___line = $_.FullName
			if ($(STRINGS-Is-Empty "${___arch_list}") -ne 0) {
				$___arch_list = "${___arch_list} "
			}

			$___arch_list = "${___arch_list}$(FS-Get-File "${___line}")"
		}
	}

	if ($(STRINGS-Is-Empty "${___arch_list}") -eq 0) {
		return 1
	}


	# purge all Package and Release files from repository
	if ($___repo_is_pool) {
		$null = FS-Remove-Silently "${___repo_directory}"
	} else {
		Get-ChildItem -Path "${___repo_directory}" `
		| Where-Object {
			($_.Name -eq "Packages") -or
			($_.Name -eq "Packages.gz") -or
			($_.Name -eq "Releases") -or
			($_.Name -eq "Releases.gpg") -or
			($_.Name -eq "InRelease")
		} | ForEach-Object {
			$null = FS-Remove-Silently $_.FullName
		}
	}


	# recreate Package files
	Get-ChildItem -Path "${___directory_package}" -File `
	| ForEach-Object { $___line = $_.FullName
		## get relative path
		$___dest = $___line -replace [regex]::Escape("${___directory_package}\"), ''

		## determine destination path
		$___dest = "$(FS-Get-Directory "${___line}")"
		if ($___repo_is_pool) {
			$___dest = "${___repo_directory}\${___dest}"
		} else {
			if ("${___dest}" -ne "${___line}") {
				# skip - it is a pool mode package in flat mode operation
				continue
			}

			$___dest = "${___repo_directory}"
		}
		$null = FS-Make-Directory "${___dest}"

		## append package entry
		$___process = FS-Is-File "${___dest}\Packages"
		if ($___process -eq 0) {
			$___process = FS-Append-File "${___dest}\Packages" "`n"
			if ($___process -ne 0) {
				return 1
			}
		}

		foreach ($___content in (Get-Content -Path "${___directory_package}\${___line}")) {
			$___process = FS-Append-File "${___dest}\Packages" "${___content}`n"
			if ($___process -ne 0) {
				return 1
			}
		}

		$null = FS-Append-File $___location "${___line}`n"
	}

	Get-ChildItem -Path "${___repo_directory}" `
	| Where-Object { ($_.Name -eq "Packages") } `
	| ForEach-Object { $___line = $_.FullName
		## gunzip all Package files
		$null = FS-Copy-File "${___line}" "${___line}.backup"
		$null = FS-Remove-Silently "${___line}.gz"
		$___process = GZ-Create "${___line}"
		if ($___process -ne 0) {
			return 1
		}

		$___process = FS-Move "${___line}.backup" "${___line}"
		if ($___process -ne 0) {
			return 1
		}

		## create corresponding legacy Release file for pool mode
		if ($___repo_is_pool) {
			$___arch = $___line -replace [regex]::Escape("${___repo_directory}\"), ''
			$___arch = "$(FS-Get-Directory "${___arch}")"

			$___arch = $___arch -split "\"
			$___suite = $___arch[0]

			$___component = $___arch[1]
			$___arch = $___arch[2] -split "-"

			$___package_type = $___arch[0]
			$___arch = $___arch[1]

			$___process = FS-Write-File `
				"$(FS-Get-Directory "${___line}")\Release" ` @"
Archive: ${___suite}
Component: ${___component}
Architecture: ${___arch}

"@
			if ($___process -ne 0) {
				return 1
			}
		}
	}


	# generate repository metadata
	if ($___repo_is_pool) {
		$___repo_directory = "${___repo_directory}\${___distribution}"
	}
	$___dest_release = "${___repo_directory}\Release"
	$null = FS-Remove-Silently "${___dest_release}"
	$___dest_inrelease = "${___repo_directory}\InRelease"
	$null = FS-Remove-Silently "${___dest_inrelease}"
	$___dest_md5 = "${___repo_directory}\ReleaseMD5"
	$null = FS-Remove-Silently "${___dest_md5}"
	$___dest_sha1 = "${___repo_directory}\ReleaseSHA1"
	$null = FS-Remove-Silently "${___dest_sha1}"
	$___dest_sha256 = "${___repo_directory}\ReleaseSHA256"
	$null = FS-Remove-Silently "${___dest_sha256}"

	Get-ChildItem -Path "${___repo_directory}" `
	| Where-Object {
		($_.Name -eq "Packages") -or
		($_.Name -eq "Packages.gz") -or
		($_.Name -eq "Release")
	} | ForEach-Object { $___line = $_.FullName
		$___size = "$(DISK-Calculate-Size-File-Byte "${___line}")"
		$___path = $___line -replace [regex]::Escape("${___repo_directory}\"), ''

		$___checksum = "$(MD5-Create-From-File "${___line}")"
		$___process = FS-Append-File "${___dest_md5}" `
			" ${___checksum} ${___size} ${___path}`n"
		if ($___process -ne 0) {
			return 1
		}

		$___checksum = "$(SHASUM-Create-From-File "${___line}" "1")"
		$___process = FS-Append-File "${___dest_sha1}" `
			" ${___checksum} ${___size} ${___path}`n"
		if ($___process -ne 0) {
			return 1
		}

		$___checksum = "$(SHASUM-Create-From-File "${___line}" "256")"
		$___process = FS-Append-File "${___dest_sha256}" `
			" ${___checksum} ${___size} ${___path}`n"
		if ($___process -ne 0) {
			return 1
		}
	}


	# create root Release file
	$___process = FS-Write-File "${___dest_release}" @"
Suite: ${___distribution}
Codename: ${___codename}
Date: $(TIME-Format-Datetime-RFC5322-UTC "$(TIME-Now)")
Architectures: ${___arch_list}
Components: ${___component}

"@
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Append-File "${___dest_release}" "MD5Sum:`n"
	if ($___process -ne 0) {
		return 1
	}
	foreach ($___line in (Get-Content -Path "${___dest_md5}")) {
		$___process = FS-Append-File "${___dest_release}" "${___line}`n"
		if ($___process -ne 0) {
			return 1
		}
	}
	$___process = FS-Remove "${___dest_md5}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Append-File "${___dest_release}" "SHA1:`n"
	if ($___process -ne 0) {
		return 1
	}
	foreach ($___line in (Get-Content -Path "${___dest_sha1}")) {
		$___process = FS-Append-File "${___dest_release}" "${___line}`n"
		if ($___process -ne 0) {
			return 1
		}
	}
	$___process = FS-Remove "${___dest_sha1}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Append-File "${___dest_release}" "SHA256:`n"
	if ($___process -ne 0) {
		return 1
	}
	foreach ($___line in (Get-Content -Path "${___dest_sha256}")) {
		$___process = FS-Append-File "${___dest_release}" "${___line}`n"
		if ($___process -ne 0) {
			return 1
		}
	}
	$___process = FS-Remove "${___dest_sha256}"
	if ($___process -ne 0) {
		return 1
	}


	# create InRelease file
	$___process = GPG-Clear-Sign-File `
		"${___dest_inrelease}" `
		"${___dest_release}" `
		"${___gpg_id}"
	if ($___process -ne 0) {
		return 1
	}


	# create Release.gpg file
	$___process = GPG-Detach-Sign-File `
		"${___dest_release}.gpg" `
		"${___dest_release}" `
		"${___gpg_id}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DEB-Unpack {
	param(
		[string]$___directory,
		[string]$___target,
		[string]$___unpack_type
	)

	# validate input
	if ($(STRINGS-Is-Empty "${___directory}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Target-Exist "${___directory}\control"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-Target-Exist "${___directory}\data"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-Target-Exist "${___directory}\debian-binary"
	if ($___process -eq 0) {
		return 1
	}


	# execute
	# copy target into directory
	$___process = FS-Copy-File "${___target}" "${___directory}"
	if ($___process -ne 0) {
		return 1
	}


	# to workspace directory
	$___current_path = Get-Location
	$null = Set-Location "${___directory}"


	# ar extract outer layer
	$___source = ".\$(FS-Get-File "${___target}")"
	$___process = AR-Extract "${___source}"
	if ($___process -ne 0) {
		$null = Set-Location -Path $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}
	$null = FS-Remove-Silently "${___source}"


	# unpack control.tar.*z by request
	if ($(STRINGS-To-Lowercase "${___unpack_type}") -ne "data") {
		$___source=".\control.tar.xz"
		$___dest=".\control"
		$null = FS-Make-Directory "${___dest}"
		$___process = FS-Is-File "${___source}"
		if ($___process -eq 0) {
			$___process = TAR-Extract-XZ "${___dest}" "${___source}"
		} else {
			$___source=".\control.tar.gz"
			$___process = FS-Is-File "${___source}"
			if ($___process -ne 0) {
				$null = Set-Location -Path $___current_path
				$null = Remove-Variable -Name ___current_path
				return 1
			}

			$___process = TAR-Extract-GZ "${___dest}" "${___source}"
		}
		$null = FS-Remove-Silently "${___source}"
	}

	if ($(STRINGS-To-Lowercase "${___unpack_type}") -eq "control") {
		# stop as requested.
		$null = Set-Location -Path $___current_path
		$null = Remove-Variable -Name ___current_path


		# report status
		if ($___process -ne 0) {
			return 1
		}
		return 0
	}


	# unpack data.tar.*z by request
	$___source=".\data.tar.xz"
	$___dest=".\data"
	$null = FS-Make-Directory "${___dest}"
	$___process = FS-Is-File "${___source}"
	if ($___process -eq 0) {
		$___process = TAR-Extract-XZ "${___dest}" "${___source}"
	} else {
		$___source=".\data.tar.gz"
		$___process = FS-Is-File "${___source}"
		if ($___process -ne 0) {
			$null = Set-Location -Path $___current_path
			$null = Remove-Variable -Name ___current_path
			return 1
		}

		$___process = TAR-Extract-GZ "${___dest}" "${___source}"
	}
	$null = FS-Remove-Silently "${___source}"


	# back to current directory
	$null = Set-Location -Path $___current_path
	$null = Remove-Variable -Name ___current_path


	# report status
	if ($___process -ne 0) {
		return 1
	}
	return 0
}
