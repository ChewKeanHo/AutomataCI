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
function FS-Append-File {
	param (
		[string]$__target,
		[string]$__content
	)

	# validate target
	if ([string]::IsNullOrEmpty($__target)) {
		return 1
	}

	# perform file write
	$__content | Out-File -FilePath $__target -Encoding utf8 -Append

	# report status
	if ($?) {
		return 0
	}

	return 1
}




function FS-Copy-All {
	param (
		[string]$__source,
		[string]$__destination
	)

	# validate input
	if ([string]::IsNullOrEmpty($__source) -or [string]::IsNullOrEmpty($__destination)) {
		return 1
	}

	# execute
	$null = Copy-Item -Path "${__source}\*" -Destination "${__destination}" -Recurse

	# report status
	if ($?) {
		return 0
	}
	return 1
}




function FS-Copy-File {
	param (
		[string]$__source,
		[string]$__destination
	)

	# validate input
	if ([string]::IsNullOrEmpty($__source) -or [string]::IsNullOrEmpty($__destination)) {
		return 1
	}

	# execute
	$null = Copy-Item -Path "${__source}" -Destination "${__destination}"

	# report status
	if ($?) {
		return 0
	}

	return 1
}




function FS-Is-Directory {
	param (
		[string]$__target
	)

	# execute
	if ([string]::IsNullOrEmpty($__target)) {
		return 1
	}

	if (Test-Path -Path "${__target}" -PathType Container -ErrorAction SilentlyContinue) {
		return 0
	}

	return 1
}




function FS-Is-File {
	param (
		[string]$__target
	)

	# execute
	if ([string]::IsNullOrEmpty($__target)) {
		return 1
	}

	$__process = FS-Is-Directory "${__target}"
	if ($__process -eq 0) {
		return 1
	}

	if (Test-Path -Path "${__target}" -ErrorAction SilentlyContinue) {
		return 0
	}

	return 1
}




function FS-Is-Target-A-Source {
	param (
		[string]$__subject
	)

	# execute
	if ($("${__subject}" -replace '^.*-src') -ne "${__subject}") {
		return 0
	}

	# report status
	return 1
}




function FS-Is-Target-Exist {
	param (
		[string]$__target
	)

	# validate input
	if ([string]::IsNullOrEmpty("${__target}")) {
		return 1
	}

	# perform checking
	$__process = Test-Path -Path "${__target}" -ErrorAction SilentlyContinue

	# report status
	if ($__process) {
		return 0
	}
	return 1
}




function FS-List-All {
	param (
		[string]$__target
	)

	# validate input
	if ([string]::IsNullOrEmpty("${__target}")) {
		return 1
	}

	# execute
	if ((FS-Is-Directory "${__target}") -ne 0) {
		return 1
	}

	try {
		foreach ($__item in (Get-ChildItem -Path "${__target}" -Recurse)) {
			Write-Host $__item.FullName
		}

		return 0
	} catch {
		return 1
	}
}




function FS-Make-Directory {
	param (
		[string]$__target
	)

	# validate input
	if ([string]::IsNullOrEmpty("${__target}")) {
		return 1
	}

	$__process = FS-Is-Directory "${__target}"
	if ($__process -eq 0) {
		return 0
	}

	$__process = FS-Is-Target-Exist "${__target}"
	if ($__process -eq 0) {
		return 1
	}

	# execute
	$__process = New-Item -ItemType Directory -Force -Path "${__target}"

	# report status
	if ($__process) {
		return 0
	}
	return 1
}




function FS-Make-Housing-Directory {
	param (
		[string]$__target
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target)) {
		return 1
	}

	$__process = FS-Is-Directory $__target
	if ($__process -eq 0) {
		return 0
	}

	# perform create
	$__process = FS-Make-Directory (Split-Path -Path $__target)

	# report status
	return $__process
}




function FS-Move {
	param (
		[string]$__source,
		[string]$__destination
	)

	# validate input
	if ([string]::IsNullOrEmpty($__source) -or [string]::IsNullOrEmpty($__destination)) {
		return 1
	}

	# execute
	Move-Item -Path $__source -Destination $__destination -Force

	# report status
	if ($?) {
		return 0
	}

	return 1
}




function FS-Remake-Directory {
	param (
		[string]$__target
	)

	# execute
	$null = FS-Remove-Silently "${__target}"
	$__process = FS-Make-Directory "${__target}"

	# report status
	if ($__process -eq 0) {
		return 0
	}
	return 1
}




function FS-Remove {
	param (
		[string]$__target
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target)) {
		return 1
	}

	# execute
	$__process = Remove-Item $__target -Force -Recurse

	# report status
	if ($__process -eq $null) {
		return 0
	}

	return 1
}




function FS-Remove-Silently {
	param (
		[string]$__target
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target)) {
		return 0
	}

	# execute
	$null = Remove-Item $__target -Force -Recurse -ErrorAction SilentlyContinue

	# report status
	return 0
}




function FS-Rename {
	param (
		[string]$__source,
		[string]$__target
	)

	# execute
	return FS-Move "${__source}" "${__target}"
}




function FS-Touch-File {
	param(
		[string]$__target
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target)) {
		return 1
	}

	$__process = FS-Is-File "${__target}"
	if ($__process -eq 0) {
		return 0
	}

	# execute
	$__process = New-Item -Path "${__target}"

	# report status
	if ($__process) {
		return 0
	}

	return 1
}




function FS-Write-File {
	param (
		[string]$__target,
		[string]$__content
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target)) {
		return 1
	}

	$__process = FS-Is-File "${__target}"
	if ($__process -eq 0) {
		return 1
	}

	# perform file write
	$__content | Out-File -FilePath $__target -Encoding utf8

	# report status
	if ($?) {
		return 0
	}

	return 1
}
