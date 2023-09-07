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




function COPYRIGHT-Create-DEB {
	param (
		[string]$__directory,
		[string]$__manual_file,
		[string]$__is_native,
		[string]$__sku,
		[string]$__name,
		[string]$__email,
		[string]$__website
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		[string]::IsNullOrEmpty($__manual_file) -or
		(-not (Test-Path $__manual_file)) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website)) {
		return 1
	}

	# checck if is the document already injected
	$__location = "${__directory}\data\usr\local\share\doc\${__sku}\copyright"
	if (Test-Path "${__location}") {
		return 0
	}

	if ($__is_native == "true") {
		$__location = "${__directory}\data\usr\share\doc\${__sku}\copyright"
		if (Test-Path "${__location}") {
			return 0
		}
	}

	# create baseline
	$__process = COPYRIGHT-Create-Baseline-DEB `
		"${__location}" `
		"${__manual_file}" `
		"${__sku}" `
		"${__name}" `
		"${__email}" `
		"${__website}"

	# report status
	return $__process
}




function COPYRIGHT-Create-RPM {
	param (
		[string]$__directory,
		[string]$__manual_file,
		[string]$__is_native,
		[string]$__sku,
		[string]$__name,
		[string]$__email,
		[string]$__website
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		[string]::IsNullOrEmpty($__manual_file) -or
		(-not (Test-Path $__manual_file)) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website)) {
		return 1
	}

	# checck if is the document already injected
	$__location = "${__directory}\BUILD\copyright"
	if (Test-Path "${__location}") {
		return 0
	}

	# create baseline
	$__process = COPYRIGHT-Create-Baseline-DEB `
		"${__location}" `
		"${__manual_file}" `
		"${__sku}" `
		"${__name}" `
		"${__email}" `
		"${__website}"

	# report status
	return $__process
}




function COPYRIGHT-Create-Baseline-DEB {
	param (
		[string]$__location,
		[string]$__manual_file,
		[string]$__sku,
		[string]$__name,
		[string]$__email,
		[string]$__website
	)

	# validate input
	if ([string]::IsNullOrEmpty($__location) -or
		(Test-Path $__location -PathType Container) -or
		[string]::IsNullOrEmpty($__manual_file) -or
		(-not (Test-Path $__manual_file)) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website)) {
		return 1
	}

	# create housing directory path
	$null = FS-Make-Housing-Directory "${__location}"

	# create copyright stanza header
	$__process = FS-Write-File "${__location}" @"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${__sku}
Upstream-Contact: ${__name} <${__email}>
Source: ${__website}

"@
	if ($__process -ne 0) {
		return 1
	}

	# append manually facilitated copyright contents
	Get-Content -Path $__manual_file | ForEach-Object {
		$null = FS-Append-File "${__location}" "${_}"
	}

	# report status
	return 0
}
