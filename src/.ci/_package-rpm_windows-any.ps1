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
	if ("$(STRINGS-To-Lowercase "$PROJECT_RPM_IS_NATIVE")" -eq "true") {
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
			$__source = "${env:PROJECT_SCOPE}\${env:PROJECT_SKU}"
			$__dest = "${_directory}\BUILD\${__source}"
			$__target = "${_chroot}\lib"

			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = TAR-Extract-GZ "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}

			$___process = RPM-Register `
				"${_directory}" `
				"${__source}" `
				"${__target}" `
				"true"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} elseif ($(FS-Is-Target-A-TARXZ "${_target}" -eq 0)) {
			# unpack library
			$__source = "${env:PROJECT_SCOPE}\${env:PROJECT_SKU}"
			$__dest = "${_directory}\BUILD\${__source}"
			$__target = "${_chroot}\lib"

			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = TAR-Extract-XZ "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}

			$___process = RPM-Register `
				"${_directory}" `
				"${__source}" `
				"${__target}" `
				"true"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} elseif ($(FS-Is-Target-A-ZIP "${_target}" -eq 0)) {
			# unpack library
			$__source = "${env:PROJECT_SCOPE}\${env:PROJECT_SKU}"
			$__dest = "${_directory}\BUILD\${__source}"
			$__target = "${_chroot}\lib"

			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = ZIP-Extract "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}

			$___process = RPM-Register `
				"${_directory}" `
				"${__source}" `
				"${__target}" `
				"true"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} else {
			# copy library file
			$__source = "$(FS-Get-File "${_target}")"
			$___dest = "${_directory}\BUILD\${__source}"
			$__target = "${_chroot}\lib"

			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = FS-Copy-File "${_target}" "${__dest}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}

			$___process = RPM-Register "${_directory}" "${__source}" "${__target}"
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
		$__source = "$(FS-Get-File "${_target}")"
		$__dest = "${_directory}\BUILD\${__source}"
		$__target = "${_chroot}\bin\${env:PROJECT_SKU}"

		$null = I18N-Assemble "${_target}" "${__dest}"
		$null = FS-Make-Directory "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}

		$___process = RPM-Register "${_directory}" "${__source}" "${__target}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}

		$_package = "${env:PROJECT_SKU}"
	}


	# NOTE: REQUIRED file
	$__source = "copyright"
	$__dest = "${_directory}/BUILD/${__source}"
	$__target = "${_chroot}/share/doc/${env:PROJECT_SCOPE}/${env:PROJECT_SKU}/${__source}"
	$null = I18N-Create "${___source}"
	$___process = COPYRIGHT-Create `
		"${__dest}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\licenses\deb-copyright" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}

	$___process = RPM-Register "${_directory}" "${__source}" "${__target}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# NOTE: REQUIRED file
	$__source = "${env:PROJECT_SCOPE}-${env:PROJECT_SKU}.1"
	$__dest = "${_directory}/BUILD/${__source}"
	$__source = "${__source}.gz"
	$__target = "${_chroot}/share/man/man1/${__source}"
	$null = I18N-Create "${__source}"
	$___process = MANUAL-Create `
		"${__dest}" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}

	$___process = RPM-Register "${_directory}" "${__source}" "${__target}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# NOTE: OPTIONAL (Comment to turn it off)
	$null = I18N-Create "source.repo"
	$___metalink = ""
	if ($(STRINGS-IS-Empty "${env:PROJECT_RPM_FLAT_MODE}") -ne 0) {
		# flat mode enabled
		if ($(STRINGS-IS-Empty "${env:PROJECT_RPM_METALINK}") -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}

		$___metalink = "${env:PROJECT_RPM_URL}\${env:PROJECT_RPM_METALINK}"
	}

	$___process = RPM-Create-Source-Repo `
		"${env:PROJECT_SIMULATE_RUN}" `
		"${_directory}" `
		"${env:PROJECT_GPG_ID}" `
		"${env:PROJECT_RPM_URL}" `
		"${___metalink}" `
		"${env:PROJECT_NAME}" `
		"${env:PROJECT_SCOPE}" `
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
