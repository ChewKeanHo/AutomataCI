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




function NOTARY-Apple-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "codesign"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "ditto"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "xcrun"
	if ($___process -ne 0) {
		return 1
	}

	if ($(STRINGS-IS-Empty "${env:APPLE_DEVELOPER_ID}") -eq 0) {
		return 1
	}

	if ($(STRINGS-IS-Empty "${env:APPLE_KEYCHAIN_PROFILE}") -eq 0) {
		return 1
	}


	# report status
	return 0
}




function NOTARY-Microsoft-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "signtool"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${env:MICROSOFT_CERT}"
	if ($___process -ne 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:MICROSOFT_CERT_TYPE}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:MICROSOFT_CERT_TIMESTAMP}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:MICROSOFT_CERT_HASH}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:MICROSOFT_CERT_PASSWORD}") -eq 0) {
		return 1
	}


	# report status
	return 0
}




function NOTARY-Setup-Microsoft {
	# report status
	return 0 # not applicable
}




function NOTARY-Sign-Apple {
	param (
		[string]$___file,
		[string]$___destination
	)


	# validate input
	$___process = NOTARY-Apple-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	if (($(STRINGS-Is-Empty "${___file}") -eq 0) -or
		($(STRINGS-Is-Empty "${___destination}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___file}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___arguments = "--force " `
		+ "--options " `
		+ "runtime " `
		+ "--deep " `
		+ "--sign " `
		+ "${env:APPLE_DEVELOPER_ID} " `
		+ "${___file}"
	$___process = OS-Exec "codesign" "${___arguments}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Exec "ditto" "-c -k --keepParent ${___file} ${___file}.zip"
	if ($___process -ne 0) {
		return 1
	}

	$___arguments = "notarytool " `
		+ "submit " `
		+ "${___file}.zip " `
		+ "--keychain-profile `"${env:APPLE_KEYCHAIN_PROFILE}`" " `
		+ "--wait"
	$___process = OS-Exec "xcrun" "${___arguments}"
	if ($___process -ne 0) {
		return 1
	}

	$null = FS-Remove-Silently "${___file}.zip"

	$___process = OS-Exec "xcrun" "stapler staple `"${___file}`""
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Move "${___file}" "${___destination}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NOTARY-Sign-Microsoft {
	param (
		[string]$___file,
		[string]$___destination,
		[string]$___name,
		[string]$___website
	)


	# validate input
	$___process = NOTARY-Microsoft-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	if (($(STRINGS-Is-Empty "${___name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___website}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___file}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	switch (${env:MICROSOFT_CERT_TYPE}) {
	PKCS12 {
		$___arguments = "sign " `
			+ "/f ${env:MICROSOFT_CERT} " `
			+ "/fd ${env:MICROSOFT_CERT_HASH} " `
			+ "/p ${env:MICROSOFT_CERT_PASSWORD} " `
			+ "/n ${___name} " `
			+ "/du ${___website} " `
			+ "/t ${env:MICROSOFT_CERT_TIMESTAMP} " `
			+ "${___file}"
	} default {
		return 1
	}}

	$___process = OS-Exec "signtool" "${___arguments}"
	if ($___process -ne 0) {
		return 1
	}

	$null = FS-Move "${___file}" "${___destination}"


	# report status
	return 0
}
