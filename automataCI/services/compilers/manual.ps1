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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compress\gz.ps1"




function MANUAL-Is-Available {
	$__process = GZ-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	return 0
}




function MANUAL-Create-DEB-Manpage {
	param(
		[string]$__directory,
		[string]$__is_native,
		[string]$__sku,
		[string]$__name,
		[string]$__email,
		[string]$__website
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		[string]::IsNullOrEmpty($__is_native) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website)) {
		Remove-Variable -Name __directory
		Remove-Variable -Name __is_native
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 1
	}

	# check if is the document already injected
	$__location = "${__directory}\data\usr\local\share\man\man1\${__sku}.1"
	if (Test-Path "${__location}.gz") {
		Remove-Variable -Name __location
		Remove-Variable -Name __directory
		Remove-Variable -Name __is_native
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 0
	}

	if ($__is_native == "true") {
		$__location = "${__directory}\data\usr\share\man\man1\${__sku}.1"
		if (Test-Path "${__location}.gz") {
			Remove-Variable -Name __location
			Remove-Variable -Name __directory
			Remove-Variable -Name __is_native
			Remove-Variable -Name __sku
			Remove-Variable -Name __name
			Remove-Variable -Name __email
			Remove-Variable -Name __website
			return 0
		}
	}

	# create manpage
	$__process = MANUAL-Create-Baseline-Manpage `
		$__location `
		$__sku `
		$__name `
		$__email `
		$__website


	# report status
	Remove-Variable -Name __location
	Remove-Variable -Name __directory
	Remove-Variable -Name __is_native
	Remove-Variable -Name __sku
	Remove-Variable -Name __name
	Remove-Variable -Name __email
	Remove-Variable -Name __website
	return $__process
}




function MANUAL-Create-RPM-Manpage {
	param(
		[string]$__directory,
		[string]$__sku,
		[string]$__name,
		[string]$__email,
		[string]$__website
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path $__directory -PathType Container)) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website)) {
		Remove-Variable -Name __directory
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 1
	}

	# check if is the document already injected
	$__location = "${__directory}\BUILD\${__sku}.1"
	if (Test-Path "${__location}.gz") {
		Remove-Variable -Name __location
		Remove-Variable -Name __directory
		Remove-Variable -Name __is_native
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 0
	}

	# create manpage
	$__process = MANUAL-Create-Baseline-Manpage `
		$__location `
		$__sku `
		$__name `
		$__email `
		$__website

	# report status
	Remove-Variable -Name __location
	Remove-Variable -Name __directory
	Remove-Variable -Name __sku
	Remove-Variable -Name __name
	Remove-Variable -Name __email
	Remove-Variable -Name __website
	return $__process
}




function MANUAL-Create-Baseline-Manpage {
	param(
		[string]$__location,
		[string]$__sku,
		[stirng]$__name,
		[string]$__email,
		[string]$__website
	)

	# validate input
	if ([string]::IsNullOrEmpty($__location) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website)) {
		Remove-Variable -Name __location
		Remove-Variable -Name __sku
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		return 1
	}

	# create housing directory path
	$null = FS-Make-Directory (Split-Path -Parent -Path $__location)

	# create basic level 1 man page that instruct users to seek --help
	$null = FS-Remove-Silently $__location
	$__content = @".`" ${__sku} - Lv1 Manpage
.TH man 1 `"${__sku} man page`"

.SH NAME
${__sku} - Getting help

.SH SYNOPSIS
command: $ ./${__sku} help

.SH DESCRIPTION
This is a backward-compatible auto-generated system-level manual page. To make
sure you get the required and proper assistances from the software, please make
sure you call the command above.

.SH SEE ALSO
Please visit ${__website} for more info.

.SH AUTHORS
Contact: ${__name} <${__email}>
"@
	$null = FS-Write-File $__location $__content

	# gunzip the manual
	$__process = GZ-Create $__location

	# report status
	Remove-Variable -Name __location
	Remove-Variable -Name __sku
	Remove-Variable -Name __name
	Remove-Variable -Name __email
	Remove-Variable -Name __website
	return $__process
}
