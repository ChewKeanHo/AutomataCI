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
		[string]::IsNullOrEmpty($__manual_file) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		(-not (Test-Path $__manual_file)) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website)) {
		Remove-Variable -Name __directory
		Remove-Variable -Name __manual_file
		Remove-Variable -Name __is_native
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 1
	}

	# checck if is the document already injected
	$__location = "${__directory}\data\usr\local\share\doc\${__sku}\copyright"
	if (Test-Path $__location) {
		Remove-Variable -Name __location
		Remove-Variable -Name __directory
		Remove-Variable -Name __manual_file
		Remove-Variable -Name __is_native
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 0
	}

	if ($__is_native == "true") {
		$__location = "${__directory}\data\usr\share\doc\${__sku}\copyright"
		if (Test-Path $__location) {
			Remove-Variable -Name __location
			Remove-Variable -Name __directory
			Remove-Variable -Name __manual_file
			Remove-Variable -Name __is_native
			Remove-Variable -Name __sku
			Remove-Variable -Name __name
			Remove-Variable -Name __email
			Remove-Variable -Name __website
			return 0
		}
	}

	# create housing directory path
	$__process = FS-Make-Housing-Directory $__location
	if ($__process -ne 0) {
		Remove-Variable -Name __location
		Remove-Variable -Name __directory
		Remove-Variable -Name __manual_file
		Remove-Variable -Name __is_native
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 1
	}

	# create copyright stanza header
	$__content = @"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${__sku}
Upstream-Contact: ${__name} <${__email}>
Source: ${__website}

"@
	$__process = FS-Write-File "$__location" "$__content"
	if ($__process -ne 0) {
		Remove-Variable -Name __location
		Remove-Variable -Name __content
		Remove-Variable -Name __directory
		Remove-Variable -Name __manual_file
		Remove-Variable -Name __is_native
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 1
	}

	# append manually facilitated copyright contents
	Get-Content -Path $__manual_file | ForEach-Object {
		$__content = $_.Substring(0, [Math]::Min($_.Length, 80))
		$__process = FS-Append-File $__location $__content
		if ($__process -ne 0) {
			Remove-Variable -Name __location
			Remove-Variable -Name __content
			Remove-Variable -Name __directory
			Remove-Variable -Name __manual_file
			Remove-Variable -Name __is_native
			Remove-Variable -Name __sku
			Remove-Variable -Name __name
			Remove-Variable -Name __email
			Remove-Variable -Name __website
			return 1
		}
	}

	# report status
	Remove-Variable -Name __location
	Remove-Variable -Name __content
	Remove-Variable -Name __directory
	Remove-Variable -Name __manual_file
	Remove-Variable -Name __is_native
	Remove-Variable -Name __sku
	Remove-Variable -Name __name
	Remove-Variable -Name __email
	Remove-Variable -Name __website
	return 0
}
