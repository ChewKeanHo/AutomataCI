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
. "${env:LIBS_AUTOMATACI}\services\compilers\ipk.ps1"




function PACKAGE-Assemble-IPK-Content {
	param(
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate target before job
	switch ($_target_arch) {
	{ $_ -in "avr", "wasm" } {
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
	$_chroot = "${_directory}/data/usr"
	if ($(STRINGS-To-Lowercase "${env:PROJECT_DEB_IS_NATIVE}") -ne "true") {
		$_chroot = "${_chroot}/local"
	}

	$_gpg_keyring = "${env:PROJECT_SKU}"
	$_package = "${env:PROJECT_SKU}"
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		$__dest = "${_chroot}\lib\${env:PROJECT_SCOPE}\${env:PROJECT_SKU}"

		if ($(FS-Is-Target-A-NPM "${_target}") -eq 0) {
			return 10 # not applicable
		} elseif ($(FS-Is-Target-A-TARGZ "${_target}") -eq 0) {
			# unpack library
			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = TAR-Extract-GZ "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} elseif ($(FS-Is-Target-A-TARXZ "${_target}") -eq 0) {
			# unpack library
			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = TAR-Extract-XZ "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} elseif ($(FS-Is-Target-A-ZIP "${_target}") -eq 0) {
			# unpack library
			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = ZIP-Extract "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} else {
			# copy library file
			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = FS-Copy-File "${_target}" "${__dest}"
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
	} elseif ($(FS-Is-Target-A-NPM "${_target}") -eq 0) {
		return 10 # not applicable
	} else {
		# copy main program
		$__dest = "${_chroot}\bin\${env:PROJECT_SKU}"
		if ($_target_os -eq "windows") {
			$__dest = "${__dest}.exe"
		}

		$null = I18N-Assemble "${_target}" "${__dest}"
		$null = FS-Make-Housing-Directory "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# WARNING: THIS REQUIRED FILE MUST BE THE LAST ONE
	$null = I18N-Create "${_directory}\control\control"
	$___process = IPK-Create-Control `
		"${_directory}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}" `
		"${_package}" `
		"${env:PROJECT_VERSION}" `
		"${_target_arch}" `
		"${_target_os}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_PITCH}" `
		"${env:PROJECT_DEB_PRIORITY}" `
		"${env:PROJECT_DEB_SECTION}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs\ABSTRACTS.txt"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
