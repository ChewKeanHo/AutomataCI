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




function GIT-Is-Available {
	$__process = OS-Is-Command-Available "git"
	if ($__process -ne 0) {
		return 1
	}

	return 0
}




function GIT-Clone {
	param (
		[string]$__url,
		[string]$__name
	)

	# validate input
	if ([string]::IsNullOrEmpty($__url)) {
		return 1
	}

	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	if (-not ([string]::IsNullOrEmpty($__url)) {
		if (Test-Path $__name) {
			return 1
		}

		if (Test-Path $__name -PathType Container) {
			return 2
		}
	}

	# execute
	if (-not ([string]::IsNullOrEmpty($__url)) {
		$__process = Os-Exec "git" "clone ${__url} ${__name}"
	} else {
		$__process = Os-Exec "git" "clone ${__url}"
	}

	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}
