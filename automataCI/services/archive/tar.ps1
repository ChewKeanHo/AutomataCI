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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compress\xz.ps1"




function TAR-Is-Available {
	$__process = Get-Command "tar" -ErrorAction SilentlyContinue
	if (-not ($__process)) {
		return 1
	}

	return 0
}




function TAR-Create-XZ {
	param (
		[string]$__destination,
		[string]$__source
	)

	# validate input
	if ([string]::IsNullOrEmpty($__destination) -or
		[string]::IsNullOrEmpty($__source)) {
		return 1
	}

	if (Test-Path -Path $__destination) {
		return 1
	}

	$__process = TAR-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = XZ-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__dest = $__destination -replace '\.xz.*$'

	# create tar archive
	$__process = OS-Exec "tar" "-cvf `"${__dest}`" ${__source}"
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
