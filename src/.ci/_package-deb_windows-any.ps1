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
. "${env:LIBS_AUTOMATACI}\services\compilers\copyright.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\deb.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\manual.ps1"




function PACKAGE-Assemble-DEB-Content {
	param(
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch,
		[string]$_changelog
	)


	# validate target before job
	switch ($_target_os) {
	{ $_ -in "android", "ios", "js", "illumos", "plan9", "wasip1" } {
		return 10 # not supported in apt ecosystem yet
	} { $_ -in "windows" } {
		return 10 # not applicable
	} default {
		# accepted
	}}

	switch ($_target_arch) {
	{ $_ -in "avr", "wasm" } {
		return 10 # not applicable
	} default {
		# accepted
	}}

	$_gpg_keyring = "${env:PROJECT_SKU}"
	$_package = "${env:PROJECT_SKU}"
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		# copy main libary
		# TIP: (1) usually is: usr/local/lib
		#      (2) please avoid: lib/, lib{TYPE}/ usr/lib/, and usr/lib{TYPE}/
		$___dest = "${_directory}\data\usr\local\lib\${env:PROJECT_SKU}"

		$null = I18N-Assemble "${_target}" "${___dest}"
		$___process = FS-Make-Directory "${___dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}

		$___process = FS-Copy-File "${_target}" "${___dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
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
	} else {
		# copy main program
		# TIP: (1) usually is: usr/local/bin or usr/local/sbin
		#      (2) please avoid: bin/, usr/bin/, sbin/, and usr/sbin/
		$___dest = "${_directory}\data\usr\local\bin"

		$null = I18N-Assemble "${_target}" "${___dest}"
		$null = FS-Make-Directory "${___dest}"
		$___process = FS-Copy-File "${_target}" "${___dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# NOTE: REQUIRED file
	$_changelog_path = "${_directory}\data\usr\local\share\doc\${env:PROJECT_SKU}\changelog.gz"
	if ("${env:PROJECT_DEBIAN_IS_NATIVE}" -eq "true") {
		$_changelog_path = "${_directory}\data\usr\share\doc\${env:PROJECT_SKU}\changelog.gz"
	}

	$null = I18N-Create "${_changelog_path}"
	$___process = DEB-Create-Changelog `
		"${_changelog_path}" `
		"${_changelog}" `
		"${env:PROJECT_SKU}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# NOTE: REQUIRED file
	$_copyright = "${_directory}\data\usr\local\share\doc\${env:PROJECT_SKU}\copyright"
	if ("${env:PROJECT_DEBIAN_IS_NATIVE}" -eq "true") {
		$_copyright = "${_directory}\data\usr\share\doc\${env:PROJECT_SKU}\copyright"
	}

	$null = I18N-Create "${_copyright}"
	$___process = COPYRIGHT-Create `
		"${_copyright}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\licenses\deb-copyright" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# NOTE: REQUIRED file
	$_manual = "${_directory}\data\usr\local\share\man\man1\${env:PROJECT_SKU}.1"
	if ("${env:PROJECT_DEBIAN_IS_NATIVE}" -eq "true") {
		$_manual = "${_directory}\data\usr\share\man\man1\${env:PROJECT_SKU}.1"
	}

	$null = I18N-Create "${_manual}"
	$___process = MANUAL-Create `
		"${_manual}" `
		"${env:PROJECT_DEBIAN_IS_NATIVE}" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# NOTE: OPTIONAL (Comment to turn it off)
	$null = I18N-Create "source.list"
	$___process = DEB-Create-Source-List `
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


	# NOTE: REQUIRED file
	$null = I18N-Create "${_directory}\control\md5sum"
	$___process = DEB-Create-Checksum "${_directory}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# WARNING: THIS REQUIRED FILE MUST BE THE LAST ONE
	$null = I18N-Create "${_directory}\control\control"
	$___process = DEB-Create-Control `
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
		"${env:PROJECT_DEBIAN_PRIORITY}" `
		"${env:PROJECT_DEBIAN_SECTION}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs\ABSTRACTS.txt"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
