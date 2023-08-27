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
function TAR-Is-Available {
	$__program = Get-Command "tar" -ErrorAction SilentlyContinue
	if ($__program) {
		return 0
	}
	return 1
}




function TARXZ-Create {
	param (
		[string]$__source,
		[string]$__destination
	)

	# validate input
	if ([string]::IsNullOrEmpty($__source) -or
		[string]::IsNullOrEmpty($__destination) -or
		(-not (Test-Path $__source -PathType Container)) -or
		(Test-Path -PathType Leaf -Path $__destination) -or
		(Test-Path $__destination -PathType Container)) {
		Remove-Variable -Name __source
		Remove-Variable -Name __destination
		return 1
	}

	$__program = Get-Command "tar" -ErrorAction SilentlyContinue
	if (-not ($__program)) {
		Remove-Variable -Name __source
		Remove-Variable -Name __destination
		return 1
	}

	# create tar.xz archive
	$process = Start-Process -Wait `
		-Filepath "$__program" `
		-NoNewWindow `
		-ArgumentList "-cvJf `"${__destination}`" `"${__source}`"" `
		-PAssThru
	$__exit = 0
	if ($process.ExitCode -ne 0) {
		$__exit = 1
	}

	# report status
	Remove-Variable -Name __program
	Remove-Variable -Name __source
	Remove-Variable -Name __destination
	return $__exit
}




function GZ-Create {
	param (
		[string]$__source,
		[string]$__destination
	)

	# validate input
	if ([string]::IsNullOrEmpty($__source) -or
		[string]::IsNullOrEmpty($__destination) -or
		(Test-Path $__source -PathType Container) -or
		(Test-Path $__destination) -or
		(Test-Path $__destination -PathType Container)) {
		Remove-Variable -Name __source
		Remove-Variable -Name __destination
		return 1
	}

	$__program = Get-Command "tar" -ErrorAction SilentlyContinue
	if (-not ($__program)) {
		Remove-Variable -Name __source
		Remove-Variable -Name __destination
		return 1
	}

	# create .gz compressed target
	$process = Start-Process -Wait `
		-Filepath "$__program" `
		-NoNewWindow `
		-ArgumentList "-czvf `"${__destination}`" `"${__source}`"" `
		-PAssThru
	$__exit = 0
	if ($process.ExitCode -ne 0) {
		$__exit = 1
	}

	# report status
	Remove-Variable -Name __program
	Remove-Variable -Name __source
	Remove-Variable -Name __destination
	return $__exit
}
