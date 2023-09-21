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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\changelog.ps1"




function RPM-Is-Available {
	param(
		[string]$__os,
		[string]$__arch
	)

	# validate dependencies
	$__process = OS-Is-Command-Available "rpmbuild"
	if ($__process -ne 0) {
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

	# report status
	return 0
}




function REB-Is-Valid {
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
	if ($(${__target} -split '\.')[-1] -eq "rpm") {
		return 0
	}

	# report status
	return 1
}




function RPM-Create-Spec {
	param(
		[string]$__directory,
		[string]$__resources,
		[string]$__sku,
		[string]$__version,
		[string]$__cadence,
		[string]$__pitch,
		[string]$__name,
		[string]$__email,
		[string]$__website,
		[string]$__license
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		[string]::IsNullOrEmpty($__resources) -or
		(-not (Test-Path $__resources -PathType Container)) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__version) -or
		[string]::IsNullOrEmpty($__cadence) -or
		[string]::IsNullOrEmpty($__pitch) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website) -or
		[string]::IsNullOrEmpty($__license)) {
		return 1
	}

	# check if is the document already injected
	$__location = "${__directory}\SPECS\${__sku}.spec"
	if (Test-Path $__location) {
		return 2
	}

	# create housing directory path
	$null = FS-Make-Housing-Directory $__location

	# generate spec file's header
	$null = FS-Write-File $__location @"
Name: ${__sku}
Version: ${__version}
Summary: ${__pitch}
Release: ${__cadence}

License: ${__license}
URL: ${__website}
"@

	# generate spec file's description field
	$null = FS-Append-File $__location "%%description`n"
	if (Test-Path "${__directory}\SPEC_DESCRIPTION") {
		foreach($__line in Get-Content "${__directory}\SPEC_DESCRIPTION") {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$null = FS-Append-File $__location "${__line}`n"
		}

		$null = FS-Remove-Silently "${__directory}\SPEC_DESCRIPTION"
	} elseif (Test-Path "${__resources}\packages\DESCRIPTION.txt") {
		foreach($__line in Get-Content "${__resources}\packages\DESCRIPTION.txt") {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$null = FS-Append-File $__location "${__line}`n"
		}
	} else {
		$null = FS-Append-File $__location "`n"
	}
	$null = FS-Append-File $__location "`n"

	# generate spec file's prep field
	$null = FS-Append-File $__location "%%prep`n"
	if (Test-Path "${__directory}\SPEC_PREPARE") {
		foreach($__line in Get-Content "${__directory}\SPEC_PREPARE") {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$null = FS-Append-File $__location "${__line}`n"
		}

		$null = FS-Remove-Silently "${__directory}\SPEC_PREPARE"
	} else {
		$null = FS-Append-File $__location "`n"
	}
	$null = FS-Append-File $__location "`n"

	# generate spec file's build field
	$null = FS-Append-File $__location "%%build`n"
	if (Test-Path "${__directory}\SPEC_BUILD") {
		foreach($__line in Get-Content "${__directory}\SPEC_BUILD") {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$null = FS-Append-File $__location "${__line}`n"
		}

		$null = FS-Remove-Silently "${__directory}\SPEC_BUILD"
	} else {
		$null = FS-Append-File $__location "`n"
	}
	$null = FS-Append-File $__location "`n"

	# generate spec file's install field
	$null = FS-Append-File $__location "%%install`n"
	if (Test-Path "${__directory}\SPEC_INSTALL") {
		foreach($__line in Get-Content "${__directory}\SPEC_INSTALL") {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$null = FS-Append-File $__location "${__line}`n"
		}

		$null = FS-Remove-Silently "${__directory}\SPEC_INSTALL"
	} else {
		$null = FS-Append-File $__location "`n"
	}
	$null = FS-Append-File $__location "`n"

	# generate spec file's clean field
	$null = FS-Append-File $__location "%%clean`n"
	if (Test-Path "${__directory}\SPEC_CLEAN") {
		foreach($__line in Get-Content "${__directory}\SPEC_CLEAN") {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$null = FS-Append-File $__location "${__line}`n"
		}

		$null = FS-Remove-Silently "${__directory}\SPEC_CLEAN"
	} else {
		$null = FS-Append-File $__location "`n"
	}
	$null = FS-Append-File $__location "`n"

	# generate spec file's files field
	$null = FS-Append-File $__location "%%files`n"
	if (Test-Path "${__directory}\SPEC_FILES") {
		foreach($__line in Get-Content "${__directory}\SPEC_FILES") {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$null = FS-Append-File $__location "${__line}`n"
		}

		$null = FS-Remove-Silently "${__directory}\SPEC_FILES"
	} else {
		$null = FS-Append-File $__location "`n"
	}
	$null = FS-Append-File $__location "`n"

	# generate spec file's changelog field
	if (Test-Path "${__directory}\SPEC_CHANGELOG") {
		$null = FS-Append-File $__location "%%changelog`n"

		foreach($__line in Get-Content "${__directory}\SPEC_CHANGELOG") {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$null = FS-Append-File $__location "${__line}`n"
		}

		$null = FS-Remove-Silently "${__directory}\SPEC_CHANGELOG"
	} else {
		$__date = Get-Date -Format "ddd MMM dd yyyy"
		$__process = CHANGELOG-Assemble-RPM `
			$__location `
			$__resources `
			$__date `
			$__name `
			$__email `
			$__version `
			1
		if ($__process -ne 0) {
			return 1
		}
	}

	# report status
	return 0
}




function RPM-Create-Archive {
	param (
		[string]$__directory,
		[string]$__destination,
		[string]$__sku,
		[string]$__arch
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__destination) -or
		[string]::IsNullOrEmpty($__sku) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		(-not (Test-Path $__destination -PathType Container)) -or
		(-not (Test-Path "${__directory}\SPECS\${__sku}.spec" -PathType Container))) {
		return 1
	}

	# change directory into workspace
	$__current_path = Get-Location
	Set-Location -Path $__directory

	# archive into rpm
	$null = FS-Make-Directory ".\BUILD"
	$null = FS-Make-Directory ".\BUILDROOT"
	$null = FS-Make-Directory ".\RPMS"
	$null = FS-Make-Directory ".\SOURCES"
	$null = FS-Make-Directory ".\SPECS"
	$null = FS-Make-Directory ".\SRPMCS"
	$null = FS-Make-Directory ".\tmp"
	$__arguments = "--define `"_topdir ${__directory}`" " +
			"--target `"$__arch`" " +
			"-ba `"${__directory}\SPECS\${__sku}.spec`""
	$__process = OS-Exec "rpmbuild" "$__arguments"
	if ($__process -ne 0) {
		Set-Location -Path $__current_path
		Remove-Variable -Name __current_path
		return 1
	}

	# return back to current path
	Set-Location -Path $__current_path
	Remove-Variable -Name __current_path

	# move to destination
	foreach($__package in (Get-ChildItem -Path "${__directory}/RPMS/${__arch}")) {
		$null = FS-Remove-Silently "${__destination}\${__package}.Name"
		$null = FS-Move "$_.FullName" "${__destination}"
	}

	# report status
	return 0
}
