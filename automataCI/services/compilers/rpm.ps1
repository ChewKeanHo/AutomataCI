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
. "${env:LIBS_AUTOMATACI}\services\compilers\changelog.ps1"




function RPM-Create-Archive {
	param (
		[string]$___directory,
		[string]$___destination,
		[string]$___arch
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___destination}"
	if ($___process -ne 0) {
		return 1
	}


	# scan for spec file
	$___spec = ""
	foreach($___file in (Get-ChildItem -File -Path "${___directory}\SPECS")) {
		$___spec = $___file.FullName
		break
	}

	$___process = FS-Is-File "${___spec}"
	if ($___process -ne 0) {
		return 1
	}


	# archive into rpm
	$___current_path = Get-Location
	Set-Location -Path $___directory
	$null = FS-Make-Directory ".\BUILD"
	$null = FS-Make-Directory ".\BUILDROOT"
	$null = FS-Make-Directory ".\RPMS"
	$null = FS-Make-Directory ".\SOURCES"
	$null = FS-Make-Directory ".\SPECS"
	$null = FS-Make-Directory ".\SRPMCS"
	$null = FS-Make-Directory ".\tmp"
	$___arguments = "--define `"_topdir ${___directory}`" " +
			"--define `"debug_package %{nil}`" " +
			"--define `"__strip /bin/true`" " +
			"--target `"${___arch}`" " +
			"-ba `"${___spec}`""
	$___process = OS-Exec "rpmbuild" "${___arguments}"
	Set-Location -Path $___current_path
	Remove-Variable -Name ___current_path

	if ($___process -ne 0) {
		return 1
	}


	# move to destination
	foreach($___package in (Get-ChildItem -Path "${___directory}/RPMS/${___arch}")) {
		$null = FS-Remove-Silently "${___destination}\$($___package.Name)"
		$null = FS-Move "${___package}" "${___destination}"
	}


	# report status
	return 0
}




function RPM-Create-Source-Repo {
	param(
		[string]$___is_simulated,
		[string]$___directory,
		[string]$___gpg_id,
		[string]$___url,
		[string]$___name,
		[string]$___sku
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___is_simulated}") -ne 0) {
		return 0
	}

	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___gpg_id}") -eq 0) -or
		($(STRINGS-Is-Empty "${___url}") -eq 0) -or
		($(STRINGS-Is-Empty "${___name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory}\SPEC_INSTALL"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory}\SPEC_FILES"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___url = "${___url}/rpm"
	$___url = $___url -replace "//rpm", "/rpm"
	$___key = "usr\local\share\keyrings\${___sku}-keyring.gpg"
	$___filename = "etc\yum.repos.d\${___sku}.repo"

	$___process = FS-Is-File `
		"${___directory}\BUILD\$(Split-Path -Leaf -Path "${___filename}")"
	if ($___process -eq 0) {
		return 10
	}

	$___process = FS-Is-File `
		"${___directory}\BUILD\$(Split-Path -Leaf -Path "${___key}")"
	if ($___process -eq 0) {
		return 1
	}

	$null = FS-Make-Directory "${___directory}\BUILD"
	$___process = FS-Write-File `
		"${___directory}\BUILD\$(Split-Path -Leaf -Path "${___filename}")" @"
# WARNING: AUTO-GENERATED - DO NOT EDIT!
[${___sku}]
name=${___name}
baseurl=${___url}
gpgcheck=1
gpgkey=file:///${___key}
"@
	if ($___process -ne 0) {
		return 1
	}

	$___process = GPG-Export-Public-Keyring `
		"${___directory}\BUILD\$(Split-Path -Leaf -Path "${___key}")" `
		"${___gpg_id}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Append-File "${___directory}\SPEC_INSTALL" @"
install --directory %{buildroot}/$(Split-Path -Parent -Path "${___filename}")
install -m 0644 $(Split-Path -Leaf -Path "${___filename}") %{buildroot}/$(Split-Path -Parent -Path "${___filename}")

install --directory %{buildroot}/$(Split-Path -Parent -Path "${___key}")
install -m 0644 $(Split-Path -Leaf -Path "${___key}") %{buildroot}/$(Split-Path -Parent -Path "${___key}")
"@
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Append-File "${___directory}\SPEC_FILES" @"
/${___filename}
/${___key}
"@
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RPM-Create-Spec {
	param(
		[string]$___directory,
		[string]$___resources,
		[string]$___sku,
		[string]$___version,
		[string]$___cadence,
		[string]$___pitch,
		[string]$___name,
		[string]$___email,
		[string]$___website,
		[string]$___license,
		[string]$___description_filepath
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___resources}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0) -or
		($(STRINGS-Is-Empty "${___cadence}") -eq 0) -or
		($(STRINGS-Is-Empty "${___pitch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___email}") -eq 0) -or
		($(STRINGS-Is-Empty "${___website}") -eq 0) -or
		($(STRINGS-Is-Empty "${___license}") -eq 0)) {
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


	# check if is the document already injected
	$___location = "${__directory}\SPECS\${__sku}.spec"
	$___process = FS-Is-File "${___location}"
	if ($___process -eq 0) {
		return 2
	}


	# create housing directory path
	$null = FS-Make-Housing-Directory "${___location}"


	# generate spec file's header
	$null = FS-Write-File "${___location}" @"
Name: ${___sku}
Version: ${___version}
Summary: ${___pitch}
Release: ${___cadence}

License: ${___license}
URL: ${___website}
"@


	# generate spec file's description field
	$null = FS-Append-File "${___location}" "%%description`n"

	$___written = 1
	$___process = FS-Is-File "${___directory}\SPEC_DESCRIPTION"
	if ($___process -eq 0) {
		foreach($___line in Get-Content "${___directory}\SPEC_DESCRIPTION") {
			if (($(STRINGS-Is-Empty "${___line}") -ne 0) -and
				($(STRINGS-Is-Empty "$($___line -replace "#.*$")") -eq 0)) {
				continue
			}

			$___line = $___line -replace '#.*'
			$null = FS-Append-File $___location "${___line}`n"
		}

		$null = FS-Remove-Silently "${___directory}\SPEC_DESCRIPTION"
		$___written = 0
	}

	$___process = FS-Is-File "${___description_filepath}"
	if (($___process -eq 0) -and ($___written -ne 0)) {
		foreach($___line in Get-Content "${___description_filepath}") {
			if (($(STRINGS-Is-Empty "${___line}") -ne 0) -and
				($(STRINGS-Is-Empty "$($___line -replace "#.*$")") -eq 0)) {
				continue
			}

			$___line = $___line -replace '#.*'
			$null = FS-Append-File "${___location}" "${___line}`n"
		}
	}

	if ($___written -ne 0) {
		$null = FS-Append-File "${___location}" "`n"
	}

	$null = FS-Append-File "${___location}" "`n"


	# generate spec file's prep field
	$null = FS-Append-File "${___location}" "%%prep`n"
	$___process = FS-Is-File "${___directory}\SPEC_PREPARE"
	if ($___process -eq 0) {
		foreach($___line in Get-Content "${___directory}\SPEC_PREPARE") {
			$___line = $_ -replace '#.*'
			if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
				continue
			}

			$null = FS-Append-File "${___location}" "${___line}`n"
		}

		$null = FS-Remove-Silently "${___directory}\SPEC_PREPARE"
	} else {
		$null = FS-Append-File "${___location}" "`n"
	}
	$null = FS-Append-File "${___location}" "`n"


	# generate spec file's build field
	$null = FS-Append-File "${___location}" "%%build`n"
	$___process = FS-Is-File "${___directory}\SPEC_BUILD"
	if ($___process -eq 0) {
		foreach($___line in Get-Content "${___directory}\SPEC_BUILD") {
			$___line = $_ -replace '#.*'
			if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
				continue
			}

			$null = FS-Append-File "${___location}" "${___line}`n"
		}

		$null = FS-Remove-Silently "${___directory}\SPEC_BUILD"
	} else {
		$null = FS-Append-File "${___location}" "`n"
	}
	$null = FS-Append-File "${___location}" "`n"


	# generate spec file's install field
	$null = FS-Append-File "${___location}" "%%install`n"
	$___process = FS-Is-File "${___directory}\SPEC_INSTALL"
	if ($___process -eq 0) {
		foreach ($___line in Get-Content "${___directory}\SPEC_INSTALL") {
			$___line = $_ -replace '#.*'
			if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
				continue
			}

			$null = FS-Append-File "${___location}" "${___line}`n"
		}

		$null = FS-Remove-Silently "${___directory}\SPEC_INSTALL"
	} else {
		$null = FS-Append-File "${___location}" "`n"
	}
	$null = FS-Append-File "${___location}" "`n"


	# generate spec file's clean field
	$null = FS-Append-File "${___location}" "%%clean`n"
	$___process = FS-Is-File "${___directory}\SPEC_CLEAN"
	if ($___process -eq 0) {
		foreach($___line in Get-Content "${___directory}\SPEC_CLEAN") {
			$___line = $_ -replace '#.*'
			if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
				continue
			}

			$null = FS-Append-File "${___location}" "${___line}`n"
		}

		$null = FS-Remove-Silently "${___directory}\SPEC_CLEAN"
	} else {
		$null = FS-Append-File "${___location}" "`n"
	}
	$null = FS-Append-File "${___location}" "`n"


	# generate spec file's files field
	$null = FS-Append-File $___location "%%files`n"
	$___process = FS-Is-File "${___directory}\SPEC_FILES"
	if ($___process -eq 0) {
		foreach($___line in Get-Content "${___directory}\SPEC_FILES") {
			$___line = $_ -replace '#.*'
			if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
				continue
			}

			$null = FS-Append-File "${___location}" "${___line}`n"
		}

		$null = FS-Remove-Silently "${__directory}\SPEC_CLEAN"
	} else {
		$null = FS-Append-File "${___location}" "`n"
	}
	$null = FS-Append-File "${___location}" "`n"


	# generate spec file's changelog field
	$___process = FS-Is-File "${___directory}\SPEC_CHANGELOG"
	if ($___process -eq 0) {
		$null = FS-Append-File "${___location}" "%%changelog`n"

		foreach($___line in Get-Content "${__directory}\SPEC_CHANGELOG") {
			$___line = $_ -replace '#.*'
			if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
				continue
			}

			$null = FS-Append-File "${___location}" "${___line}`n"
		}

		$null = FS-Remove-Silently "${___directory}\SPEC_CHANGELOG"
	} else {
		$___date = Get-Date -Format "ddd MMM dd yyyy"
		$___process = CHANGELOG-Assemble-RPM `
			"${___location}" `
			"${___resources}" `
			"${___date}" `
			"${___name}" `
			"${___email}" `
			"${___version}" `
			1
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function RPM-Is-Available {
	param(
		[string]$___os,
		[string]$___arch
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0)) {
		return 1
	}

	$___process = OS-Is-Command-Available "rpmbuild"
	if ($___process -ne 0) {
		return 1
	}


	# check compatible target os
	switch ($___os) {
	linux {
		break
	} default {
		return 2
	}}


	# check compatible target cpu architecture
	switch ($___arch) {
	any {
		return 3
	} default {
		Break
	}}


	# report status
	return 0
}




function RPM-Is-Valid {
	param (
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "$1"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	if ($(${__target} -split '\.')[-1] -eq "rpm") {
		return 0
	}


	# report status
	return 1
}
