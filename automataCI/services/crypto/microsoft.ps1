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




function MICROSOFT-Sign {
	param (
		[string]$__file,
		[string]$__destination,
		[string]$__name,
		[string]$__website
	)


	# validate input
	$__process = MICROSOFT-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	if ([string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__website) -or
		(-not (Test-Path -Path "${__file}"))) {
		return 1
	}


	# execute
	switch (${env:MICROSOFT_CERT_TYPE}) {
	PKCS12 {
		$__arguments = "sign " `
			+ "/f ${env:MICROSOFT_CERT} " `
			+ "/fd ${env:MICROSOFT_CERT_HASH} " `
			+ "/p ${env:MICROSOFT_CERT_PASSWORD} " `
			+ "/n ${__name} " `
			+ "/du ${__website} " `
			+ "/t ${env:MICROSOFT_CERT_TIMESTAMP} " `
			+ "${__file}"
	} default {
		return 1
	}}

	$__process = OS-Exec "signtool" "${__arguments}"
	if ($__process -ne 0) {
		return 1
	}

	$null = FS-Move "${__file}" "${__destination}"


	# report status
	return 0
}




function MICROSOFT-Is-Available {
	# execute
	$__process = OS-Is-Command-Available "signtool"
	if ($__process -ne 0) {
		return 1
	}

	if (-not (Test-Path -Path "${env:MICROSOFT_CERT}")) {
		return 1
	}

	if ([string]::IsNullOrEmpty(${env:MICROSOFT_CERT_TYPE})) {
		return 1
	}

	if ([string]::IsNullOrEmpty(${env:MICROSOFT_CERT_TIMESTAMP})) {
		return 1
	}

	if ([string]::IsNullOrEmpty(${env:MICROSOFT_CERT_HASH})) {
		return 1
	}

	if ([string]::IsNullOrEmpty(${env:MICROSOFT_CERT_PASSWORD})) {
		return 1
	}


	# report status
	return 0
}
