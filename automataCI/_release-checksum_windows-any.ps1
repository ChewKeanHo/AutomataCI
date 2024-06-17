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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\crypto\gpg.ps1"
. "${env:LIBS_AUTOMATACI}\services\checksum\shasum.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Conclude-CHECKSUM {
	param (
		[string]$__repo_directory
	)


	# execute
	$__sha256_file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\releaser-sha256.txt"
	$null = FS-Remove-Silently "${__sha256_file}"

	$__sha512_file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\releaser-sha512.txt"
	$null = FS-Remove-Silently "${__sha512_file}"

	$__sha256_target = "${env:PROJECT_SKU}-sha256_${env:PROJECT_VERSION}.txt"
	$__sha256_target = "${__repo_directory}\${__sha256_target}"
	$null = FS-Remove-Silently "${__sha256_target}"

	$__sha512_target = "${env:PROJECT_SKU}-sha512_${env:PROJECT_VERSION}.txt"
	$__sha512_target = "${__repo_directory}\${__sha512_target}"
	$null = FS-Remove-Silently "${__sha512_target}"


	# gpg sign all packages
	$___process = GPG-Is-Available "${env:PROJECT_GPG_ID}"
	if ($___process -eq 0) {
		$__keyfile = "${env:PROJECT_SKU}-gpg_${env:PROJECT_VERSION}.keyfile"
		$__keyfile = "${__repo_directory}\${__keyfile}"

		$null = I18N-Publish "${__keyfile}"
		$null = FS-Remove-Silently "${__keyfile}"
		if ($(OS-Is-Run-Simulated) -ne 0) {
			$___process = GPG-Export-Public-Key `
				"${__keyfile}" `
				"${env:PROJECT_GPG_ID}"
			if ($___process -ne 0) {
				$null = I18N-Publish-Failed
				return 1
			}
		} else {
			$null = I18N-Simulate-Publish "${__keyfile}"
		}

		foreach ($TARGET in (Get-ChildItem -Path "${__repo_directory}")) {
			$TARGET = $TARGET.FullName

			if ($("${TARGET}" -replace '^.*.asc') -ne "${TARGET}") {
				continue # it's a gpg cert
			}

			if ($("${TARGET}" -replace '^.*.gpg') -ne "${TARGET}") {
				continue # it's a gpg keyfile or cert
			}

			$null = I18N-Sign "${TARGET}" "GPG"
			if ($(OS-Is-Run-Simulated) -eq 0) {
				$null = I18N-Simulate-Notarize "${TARGET}"
				continue
			}

			FS-Remove-Silently "${TARGET}.asc"
			$___process = GPG-Detach-Sign-File `
				"${TARGET}.asc" `
				"${TARGET}" `
				"${env:PROJECT_GPG_ID}"
			if ($___process -ne 0) {
				$null = I18N-Sign-Failed
				return 1
			}
		}
	}


	# shasum all files
	foreach ($TARGET in (Get-ChildItem -Path "${__repo_directory}")) {
		$TARGET = $TARGET.FullName

		$___process = FS-Is-Directory "${TARGET}"
		if ($___process -eq 0) {
			$null = I18N-Is-Directory-Skipped "${TARGET}"
			continue
		}

		if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_SHA256}") -ne 0) {
			$null = I18N-Checksum $TARGET "SHA256"
			$__value = SHASUM-Create-From-File $TARGET "256"
			if ($(STRINGS-Is-Empty "${__value}") -eq 0) {
				$null = I18N-Checksum-Failed
				return 1
			}

			$___process = FS-Append-File `
				"${__sha256_file}" `
				"${__value}  $(FS-Get-File "$TARGET")`n"
			if ($___process -ne 0) {
				$null = I18N-Checksum-Failed
				return 1
			}
		}

		if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_SHA512}") -ne 0) {
			$null = I18N-Checksum $TARGET "SHA512"
			$__value = SHASUM-Create-From-File $TARGET "512"
			if ($(STRINGS-Is-Empty "${__value}") -eq 0) {
				$null = I18N-Checksum-Failed
				return 1
			}

			$___process = FS-Append-File `
				"${__sha512_file}" `
				"${__value}  $(FS-Get-File "$TARGET")`n"
			if ($___process -ne 0) {
				$null = I18N-Checksum-Failed
				return 1
			}
		}
	}


	$___process = FS-Is-File "${__sha256_file}"
	if ($___process -eq 0) {
		$null = I18N-Conclude "${__sha256_target}"
		$___process = FS-Move "${__sha256_file}" "${__sha256_target}"
		if ($___process -ne 0) {
			$null = I18N-Conclude-Failed
			return 1
		}
	}


	$___process = FS-Is-File "${__sha512_file}"
	if ($___process -eq 0) {
		$null = I18N-Conclude "${__sha512_target}"
		$___process = FS-Move "${__sha512_file}" "${__sha512_target}"
		if ($___process -ne 0) {
			$null = I18N-Conclude-Failed
			return 1
		}
	}


	# report status
	return 0
}




function RELEASE-Initiate-CHECKSUM {
	# execute
	$null = I18N-Check-Availability "SHASUM"
	$___process = SHASUM-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}

	$null = I18N-Check-Availability "GPG"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Available "GPG"
	} else {
		$___process = GPG-Is-Available "${env:PROJECT_GPG_ID}"
		if ($___process -ne 0) {
			$null = I18N-Check-Failed
			return 1
		}
	}


	# report status
	return 0
}
