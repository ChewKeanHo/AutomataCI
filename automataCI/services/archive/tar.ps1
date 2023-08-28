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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compress\gz.ps1"




function TAR-Is-Available {
	$__process = Get-Command "tar" -ErrorAction SilentlyContinue
	if (-not ($__process)) {
		return 1
	}

	$__process = GZ-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	return 0
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

	$__process = TAR-Is-Available
	if ($__process -ne 0) {
		Remove-Variable -Name __source
		Remove-Variable -Name __destination
		return 1
	}

	# create tar.xz archive
	$__process = OS-Exec "tar -cvJf `"${__destination}`" `"${__source}`""

	# report status
	Remove-Variable -Name __program
	Remove-Variable -Name __source
	Remove-Variable -Name __destination

	return $__process
}
