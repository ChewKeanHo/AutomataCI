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




function APPLE-Sign {
	param (
		[string]$__file,
		[string]$__destination
	)


	# validate input
	$__process = APPLE-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	if ([string]::IsNullOrEmpty($__file) -or
		[string]::IsNullOrEmpty($__destination) -or
		(-not (Test-Path -Path "${__file}"))) {
		return 1
	}


	# execute
	$__arguments = "--force " `
		+ "--options " `
		+ "runtime " `
		+ "--deep " `
		+ "--sign " `
		+ "${env:APPLE_DEVELOPER_ID} " `
		+ "${__file}"
	$__process = OS-Exec "codesign" "${__arguments}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "ditto" "-c -k --keepParent ${__file} ${__file}.zip"
	if ($__process -ne 0) {
		return 1
	}

	$__arguments = "notarytool " `
		+ "submit " `
		+ "${__file}.zip " `
		+ "--keychain-profile `"${env:APPLE_KEYCHAIN_PROFILE}`" " `
		+ "--wait"
	$__process = OS-Exec "xcrun" "${__arguments}"
	if ($__process -ne 0) {
		return 1
	}

	$null = FS-Remove-Silently "${__file}.zip"

	$__process = OS-Exec "xcrun" "stapler staple `"${__file}`""
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Move "${__file}" "${__destination}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function APPLE-Is-Available {
	# execute
	$__process = OS-Is-Command-Available "codesign"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Is-Command-Available "ditto"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Is-Command-Available "xcrun"
	if ($__process -ne 0) {
		return 1
	}

	if ([string]::IsNullOrEmpty(${env:APPLE_DEVELOPER_ID})) {
		return 1
	}

	if ([string]::IsNullOrEmpty(${env:APPLE_KEYCHAIN_PROFILE})) {
		return 1
	}


	# report status
	return 0
}
