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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




function CREATEREPO-Is-Available {
	$__process = OS-Is-Command-Available "createrepo"
	if ($__process -eq 0) {
		return 0
	}

	$__process = OS-Is-Command-Available "createrepo_c"
	if ($__process -eq 0) {
		return 0
	}

	# report status
	return 1
}




function CREATEREPO-Publish {
	param (
		[string]$__target,
		[string]$__directory
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__directory) -or
		(Test-Path "${__target}" -PathType Container) -or
		(-not (Test-Path "${__directory}" -PathType Container))) {
		return 1
	}

	# execute
	$__process = FS-Copy-File "${__target}" "${__directory}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Is-Command-Available "createrepo"
	if ($__process -eq 0) {
		$__process = OS-Exec "createrepo" "--update ${__directory}"
		if ($__process -eq 0) {
			return 0
		}
	}

	$__process = OS-Is-Command-Available "createrepo_c"
	if ($__process -eq 0) {
		$__process = OS-Exec "createrepo_c" "--update ${__directory}"
		if ($__process -eq 0) {
			return 0
		}
	}

	# report status
	return 1
}
