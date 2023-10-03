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




function GPG-Detach-Sign-File {
	param (
		[string]$__target,
		[string]$__id
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		(-not (Test-Path -Path "${__target}")) -or
		[string]::IsNullOrEmpty($__id)) {
		return 1
	}

	$__process = GPG-Is-Available "${__id}"
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$__process = OS-Exec `
		"gpg" "--armor --detach-sign --local-user `"${__id}`" `"${__target}`""

	# report status
	if ($__process -eq 0) {
		return 0
	}
	return 1
}




function GPG-Export-Public-Key {
	param(
		[string]$__destination,
		[string]$__id
	)

	# validate input
	if ([string]::IsNullOrEmpty($__destination) -or [string]::IsNullOrEmpty($__id)) {
		return 1
	}

	$__process = GPG-Is-Available "${__id}"
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$null = FS-Remove-Silently "${__destination}"
	$__process = OS-Exec "gpg" "--armor --export `"${__id}`" > `"${__destination}`""

	# report status
	if ($__process -eq 0) {
		return 0
	}
	return 1
}




function GPG-Export-Public-Keyring {
	param(
		[string]$__destination,
		[string]$__id
	)


	# validate input
	if ([string]::IsNullOrEmpty($__destination) -or [string]::IsNullOrEmpty($__id)) {
		return 1
	}

	$__process = GPG-Is-Available "${__id}"
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Remove-Silently "${__destination}"
	$__process = OS-Exec "gpg" "--export `"${__id}`" > `"${__destination}`""


	# report status
	if ($__process -eq 0) {
		return 0
	}
	return 1
}




function GPG-Is-Available {
	param (
		[string]$__id
	)

	$__process = OS-Is-Command-Available "gpg"
	if ($__process -ne 0) {
		return 1
	}


	$__process = OS-Exec "gpg" "--list-key `"${__id}`""
	if ($__process -ne 0) {
		return 1
	}

	return 0
}
