# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




function GPG-Clear-Sign-File {
	param (
		[string]$___output,
		[string]$___target,
		[string]$___id
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___output}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___id}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Target-Exist "${___output}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = GPG-Is-Available "${___id}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "gpg" @"
--armor --clear-sign --local-user `"${___id}`" --output `"${___output}`" `"${___target}`"
"@
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function GPG-Detach-Sign-File {
	param (
		[string]$___output,
		[string]$___target,
		[string]$___id
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___output}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___id}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Target-Exists "${___output}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = GPG-Is-Available "${___id}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "gpg" @"
--armor --detach-sign --local-user `"${___id}`" --output `"${___output}`" `"${___target}`"
"@
	if ($___process -ne 0) {
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
	if (($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___id}") -eq 0)) {
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
	if (($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___id}") -eq 0)) {
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

	if ($(STRINGS-Is-Empty "${___id}") -eq 0) {
		return 0
	}

	$___process = OS-Exec "gpg" "--list-key `"${___id}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
