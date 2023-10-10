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




function GZ-Create {
	param (
		[string]$__source
	)


	# validate input
	$__process = GZ-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	if ([string]::IsNullOrEmpty($__source) -or (Test-Path $__source -PathType Container)) {
		return 1
	}
	$__source = $__source -replace "\.gz$"


	# create .gz compressed target
	if ((OS-Is-Command-Available "gzip") -eq 0) {
		$__process = OS-Exec "gzip" "-9 `"${__source}`""
	} elseif ((OS-Is-Command-Available "gunzip") -eq 0) {
		$__process = OS-Exec "gunzip" "-9 `"${__source}`""
	} else {
		$__process = 1
	}


	# report status
	return $__process
}




function GZ-Is-Available {
	# execute
	$__process = OS-Is-Command-Available "gzip"
	if ($__process -eq 0) {
		return 0
	}

	$__process = OS-Is-Command-Available "gunzip"
	if ($__process -eq 0) {
		return 0
	}


	# report status
	return 1
}
