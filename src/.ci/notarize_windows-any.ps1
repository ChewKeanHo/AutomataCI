# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	exit 1
}

. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\crypto\notary.ps1"




function NOTARIZE-Certify {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Chocolatey "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	}


	# notarize
	switch ($_target_os) {
	darwin {
		if ($(OS-Is-Run-Simulated) -eq 0) {
			return 12
		}

		$___process = NOTARY-Apple-Is-Available
		if ($___process -ne 0) {
			return 11
		}

		$_dest = "$(FS-Get-Directory "${_target}")"
		$_dest = "${_dest}\${_target_name}-signed_${_target_os}-${_target_arch}"
		$___process = NOTARY-Sign-Apple "${_dest}" "${_target}"
		if ($___process -ne 0) {
			return 1
		}
	} windows {
		if ($(OS-Is-Run-Simulated) -eq 0) {
			return 12
		}

		$___process = NOTARY-Microsoft-Is-Available
		if ($___process -ne 0) {
			return 11
		}

		$_dest = "$(FS-Get-Directory "${_target}")"
		$_dest = "${_dest}\${_target_name}-signed_${_target_os}-${_target_arch}.exe"
		$___process = NOTARY-Sign-Microsoft `
			"${_dest}" `
			"${_target}" `
			"${env:PROJECT_CONTACT_NAME}" `
			"${env:PROJECT_CONTACT_WEBSITE}"
		if ($___process -ne 0) {
			return 1
		}
	} default {
		return 10 # not applicable
	}}


	# report status
	return 0
}




# report status
return 0
