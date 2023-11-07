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




function HOMEBREW-Is-Valid-Formula {
	param (
		[string]$__target
	)


	# validate input
	if ([string]::IsNullOrEmpty($__target)) {
		return 1
	}

	$__process = FS-Is-Target-A-Homebrew "${__target}"
	if ($__process -ne 0) {
		return 1
	}

	if ($__target -like "*.asc") {
		return 1
	}


	# execute
	if ($__target -like "*.rb") {
		return 1
	}


	# report status
	return 1
}




function HOMEBREW-Publish {
	param (
		[string]$__target,
		[string]$__destination
	)


	# validate input
	if ([string]::IsNullOrEmpty($__target) -or [string]::IsNullOrEmpty($__destination)) {
		return 1
	}


	# execute
	$null = FS-Make-Directory "${__destination}"
	$__process = FS-Copy-File `
		"${__target}" `
		"${__destination}\$(Split-Path -Leaf -Path "${__target}")"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function HOMEBREW-Setup {
	# report status
	return 1 # unsupported
}
