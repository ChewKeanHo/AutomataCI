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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compress\xz.ps1"




function TAR-Is-Available {
	# validate input
	$__process = Get-Command "tar" -ErrorAction SilentlyContinue
	if (-not ($__process)) {
		return 1
	}


	# execute
	return 0
}




function TAR-Create {
	param (
		[string]$__destination,
		[string]$__source,
		[string]$__owner,
		[string]$__group
	)


	# validate input
	if ([string]::IsNullOrEmpty($__destination) -or [string]::IsNullOrEmpty($__source)) {
		return 1
	}

	if (Test-Path -Path $__destination) {
		return 1
	}

	$__process = TAR-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# create tar archive
	if ((-not [string]::IsNullOrEmpty($__owner)) -and [string]::IsNullOrEmpty($__group)) {
		$__arguments = "--numeric-owner --group=`"${__group}`" " `
				+ "--owner=`"${__owner}`" " `
				+ "-cvf `"${__destination}`" ${__source}"
		$__process = OS-Exec "tar" "${__arguments}"
		if ($__process -ne 0) {
			return 1
		}
	} else {
		$__process = OS-Exec "tar" "-cvf `"${__destination}`" ${__source}"
		if ($__process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function TAR-Create-GZ {
	param (
		[string]$__destination,
		[string]$__source,
		[string]$__owner,
		[string]$__group
	)


	# validate input
	if ([string]::IsNullOrEmpty($__destination) -or [string]::IsNullOrEmpty($__source)) {
		return 1
	}

	if (Test-Path -Path $__destination) {
		return 1
	}


	# create tar archive
	$__dest = $__destination -replace '\.gz.*$'
	$__process = TAR-Create "${__dest}" "${__source}" "0" "0"
	if ($__process -ne 0) {
		return 1
	}

	$__process = GZ-Create "${__dest}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function TAR-Create-XZ {
	param (
		[string]$__destination,
		[string]$__source,
		[string]$__owner,
		[string]$__group
	)


	# validate input
	if ([string]::IsNullOrEmpty($__destination) -or [string]::IsNullOrEmpty($__source)) {
		return 1
	}

	if (Test-Path -Path $__destination) {
		return 1
	}


	# create tar archive
	$__dest = $__destination -replace '\.xz.*$'
	$__process = TAR-Create "${__dest}" "${__source}" "0" "0"
	if ($__process -ne 0) {
		return 1
	}

	$__process = XZ-Create "${__dest}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
