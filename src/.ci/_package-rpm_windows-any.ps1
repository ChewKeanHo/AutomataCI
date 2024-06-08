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
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\rpm.ps1"




function PACKAGE-Assemble-RPM-Content {
	param(
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate target before job
	switch ($_target_arch) {
	{ $_ -in "avr" } {
		return 10 # not applicable
	} default {
		# accepted
	}}


	# execute
	## determine base path
	## TIP: (1) by design, usually is: usr/local/
	##      (2) please avoid: usr/, usr/{TYPE}/, usr/bin/, & usr/lib{TYPE}/
	##          whenever possible for avoiding conflicts with your OS native
	##          system packages.
	$_chroot = "usr"
	if ("$(STRINGS-To-Lowercase "$PROJECT_DEBIAN_IS_NATIVE")" -eq "true") {
		$_chroot = "${_chroot}/local"
	}

	$_gpg_keyring = "${env:PROJECT_SKU}"
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		if ($(FS-Is-Target-A-NPM "${_target}" -eq 0)) {
			return 10 # not applicable
		} elseif ($(FS-Is-Target-A-TARGZ "${_target}" -eq 0)) {
			# unpack library
			$___source = "${env:PROJECT_SCOPE}\${env:PROJECT_SKU}"
			$___dest = "${_directory}\BUILD\${___source}"
			$___target = "${_chroot}\lib\${___source}"

			$null = I18N-Assemble "${_target}" "${___dest}"
			$null = FS-Make-Directory "${___dest}"
			$___process = TAR-Extract-GZ "${___dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}

			$___process = RPM-Register `
				"${_directory}" `
				"${___source}" `
				"${___target}" `
				"true"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} elseif ($(FS-Is-Target-A-TARXZ "${_target}" -eq 0)) {
			# unpack library
			$___source = "${env:PROJECT_SCOPE}\${env:PROJECT_SKU}"
			$___dest = "${_directory}\BUILD\${___source}"
			$___target = "${_chroot}\lib\${___source}"

			$null = I18N-Assemble "${_target}" "${___dest}"
			$null = FS-Make-Directory "${___dest}"
			$___process = TAR-Extract-XZ "${___dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}

			$___process = RPM-Register `
				"${_directory}" `
				"${___source}" `
				"${___target}" `
				"true"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} elseif ($(FS-Is-Target-A-ZIP "${_target}" -eq 0)) {
			# unpack library
			$___source = "${env:PROJECT_SCOPE}\${env:PROJECT_SKU}"
			$___dest = "${_directory}\BUILD\${___source}"
			$___target = "${_chroot}\lib\${___source}"

			$null = I18N-Assemble "${_target}" "${___dest}"
			$null = FS-Make-Directory "${___dest}"
			$___process = ZIP-Extract "${___dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}

			$___process = RPM-Register `
				"${_directory}" `
				"${___source}" `
				"${___target}" `
				"true"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} else {
			# copy library file
			$___source = "$(FS-Get-File "${_target}")"
			$___dest = "${_directory}\BUILD\${___source}"
			$___target = "${_chroot}\lib\${___source}"

			$null = I18N-Assemble "${_target}" "${___dest}"
			$null = FS-Make-Directory "${___dest}"
			$___process = FS-Copy-File "${_target}" "${___dest}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}

			$___process = RPM-Register "${_directory}" "${___source}" "${___target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		}

		$_gpg_keyring = "lib${env:PROJECT_SKU}"
		$_package = "lib${env:PROJECT_SKU}"
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Chocolatey "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Cargo "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-MSI "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-PDF "${_target}") -eq 0) {
		return 10 # not applicable
	} else {
		# copy main program
		$___source = "$(FS-Get-File "${_target}")"
		$___dest = "${_directory}\BUILD\${___source}"
		$___target = "${_chroot}\lib\${___source}"

		$null = I18N-Assemble "${_target}" "${___dest}"
		$null = FS-Make-Directory "${___dest}"
		$___process = FS-Copy-File "${_target}" "${___dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}

		$___process = RPM-Register "${_directory}" "${___source}" "${___target}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}

		$_package = "${env:PROJECT_SKU}"
	}


	# NOTE: REQUIRED file
	$___source = "copyright"
	$___dest = "${_directory}/BUILD/${___source}"
	$___target = "${_chroot}/share/doc/${env:PROJECT_SCOPE}/${env:PROJECT_SKU}/${___source}"
	$null = I18N-Create "${___source}"
	$___process = COPYRIGHT-Create `
		"${___dest}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\licenses\deb-copyright" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}

	$___process = RPM-Register "${_directory}" "${___source}" "${___target}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# NOTE: REQUIRED file
	$___source = "${env:PROJECT_SCOPE}-${env:PROJECT_SKU}.1"
	$___dest = "${_directory}/BUILD/${___source}"
	$___target = "${_chroot}/share/man/man1/${___source}"
	$null = I18N-Create "${___source}"
	$___process = MANUAL-Create `
		"${___dest}" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}

	$___process = RPM-Register "${_directory}" "${___source}" "${___target}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# NOTE: OPTIONAL (Comment to turn it off)
	$null = I18N-Create "source.repo"
	$___process = RPM-Create-Source-Repo `
		"${env:PROJECT_SIMULATE_RELEASE_REPO}" `
		"${_directory}" `
		"${env:PROJECT_GPG_ID}" `
		"${env:PROJECT_STATIC_URL}" `
		"${env:PROJECT_REPREPRO_CODENAME}" `
		"${env:PROJECT_DEBIAN_DISTRIBUTION}" `
		"${_gpg_keyring}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# WARNING: THIS REQUIRED FILE MUST BE THE LAST ONE
	$null = I18N-Create "spec"
	$___process = RPM-Create-Spec `
		"${_directory}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}" `
		"${_package}" `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_CADENCE}" `
		"${env:PROJECT_PITCH}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_LICENSE}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs\ABSTRACTS.txt"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
