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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function GPG-Detach-Sign-File {
	param (
		[string]$___target,
		[string]$___id
	)


	# validate input
	if (($(STRINGS_Is_Empty "${___target}") -eq 0) -or
		($(STRINGS_Is_Empty "${___id}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = GPG-Is-Available "${___id}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec `
		"gpg" "--armor --detach-sign --local-user `"${__id}`" `"${__target}`""
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GPG-Export-Public-Key {
	param(
		[string]$___destination,
		[string]$___id
	)


	# validate input
	if (($(STRINGS_Is_Empty "${___destination}") -eq 0) -or
		($(STRINGS_Is_Empty "${___id}") -eq 0)) {
		return 1
	}

	$___process = GPG-Is-Available "${___id}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Remove-Silently "${___destination}"
	$___process = OS-Exec "gpg" "--armor --export `"${___id}`" > `"${___destination}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GPG-Export-Public-Keyring {
	param(
		[string]$___destination,
		[string]$___id
	)


	# validate input
	if (($(STRINGS_Is_Empty "${___destination}") -eq 0) -or
		($(STRINGS_Is_Empty "${___id}") -eq 0)) {
		return 1
	}

	$___process = GPG-Is-Available "${___id}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Remove-Silently "${___destination}"
	$___process = OS-Exec "gpg" "--export `"${___id}`" > `"${___destination}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GPG-Is-Available {
	param (
		[string]$___id
	)


	# execute
	$___process = OS-Is-Command-Available "gpg"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Exec "gpg" "--list-key `"${___id}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
