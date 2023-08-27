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
function FS-Copy-File {
	param (
		[string]$__source,
		[string]$__destination
	)

	# validate input
	if ([string]::IsNullOrEmpty($__source) -or
		[string]::IsNullOrEmpty($__destination)) {
		Remove-Variable -Name __source
		Remove-Variable -Name __destination
		return 1
	}

	# perform copying
	$null = Copy-Item -Path $__source -Destination $__destination
	$__exit = $?
	if ($__exit -ne 0) {
		$__exit = 1
	}

	# report status
	Remove-Variable -Name __source
	Remove-Variable -Name __destination
	return $__exit
}

function FS-IsDirectory {
	param (
		[string]$__subject
	)

	# validate input
	if ([string]::IsNullOrEmpty($__subject)) {
		Remove-Variable -Name __subject
		return 1
	}

	# perform checking
	$__process = Test-Path -Path $__subject -PathType Container

	# report status
	Remove-Variable -Name __subject
	if ($__process) {
		return 0
	}
	return 1
}

function FS-IsExists {
	param (
		[string]$__subject
	)

	# validate input
	if ([string]::IsNullOrEmpty($__subject)) {
		Remove-Variable -Name __subject
		return 1
	}

	# perform checking
	$__process = Test-Path -Path $__subject


	# report status
	Remove-Variable -Name __subject
	if ($__process) {
		return 0
	}
	return 1
}

function FS-List-All {
	param (
		[string]$__target
	)

	# validate target
	if ([string]::IsNullOrEmpty($__target)) {
		Remove-Variable -Name __target
		return 1
	}

	# perform listing
	if (-not (FS-IsDirectory $__target)) {
		Remove-Variable -Name __target
		return 1
	}

	try {
		foreach ($__item in (Get-ChildItem -Path $__target -Recurse)) {
			Write-Host $__item.FullName
		}
		Remove-Variable -Name __target
		return 0
	} catch {
		Remove-Variable -Name __target
		return 1
	}
}

function FS-Remove {
	param (
		[string]$__target
	)

	# validate target
	if ([string]::IsNullOrEmpty($__target)) {
		Remove-Variable -Name __target
		return 1
	}

	# perform remove
	$__process = Remove-Item $__target -Force -Recurse
	Remove-Variable -Name __target
	if ($__process -eq $null) {
		return 0
	}
	return 1
}

function FS-Remove-Silently {
	param (
		[string]$__target
	)

	# validate target
	if ([string]::IsNullOrEmpty($__target)) {
		Remove-Variable -Name __target
		return 1
	}

	# perform remove
	Remove-Item $__target -Force -Recurse -ErrorAction SilentlyContinue
	return 0
}

function FS-Rename {
	param (
		[string]$__source,
		[string]$__target
	)

	# validate input
	if ([string]::IsNullOrEmpty($__source) -or
		[string]::IsNullOrEmpty($__target) -or
		(-not (Test-Path -Path $__source -PathType Container)) -or
		(-not (Test-Path -Path $__source)) -or
		(Test-Path -Path $__target -PathType Container) -or
		(Test-Path -Path $__target)) {
		Remove-Variable -Name __source
		Remove-Variable -Name __target
		return 1
	}

	# perform rename
	$__process = Move-Item -Path $__source -Destination $__target
	if ($?) {
		$__exit = 0
	} else {
		$__exit = 1
	}

	# report status
	Remove-Variable -Name __process
	Remove-Variable -Name __source
	Remove-Variable -Name __target
	return $__exit
}

function FS-Make-Directory {
	param (
		[string]$__target
	)

	# validate target
	if ([string]::IsNullOrEmpty($__target) -or
		(Test-Path -Path $__target -PathType Container) -or
		(Test-Path -Path $__target)) {
		Remove-Variable -Name __target
		return 1
	}

	# perform create
	$__process = New-Item -ItemType Directory -Force -Path $__target
	Remove-Variable -Name __target

	# report status
	if ($__process) {
		return 0
	}
	return 1
}

function FS-Remake-Directory {
	param (
		[string]$__target
	)

	$__process = FS-Remove-Silently $__target
	$__process = FS-Make-Directory $__target
	if ($__process -eq 0) {
		return 0
	}
	return 1
}
