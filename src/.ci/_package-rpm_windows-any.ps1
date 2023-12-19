# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




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


	$_gpg_keyring = "${env:PROJECT_SKU}"
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		# copy main libary
		# TIP: (1) usually is: usr/local/lib
		#      (2) please avoid: lib/, lib{TYPE}/ usr/lib/, and usr/lib{TYPE}/
		$_filepath = "${_directory}\BUILD\lib${env:PROJECT_SKU}.a"
		OS-Print-Status info "copying ${_target} to ${_filepath}"
		$__process = FS-Make-Housing-Directory "${_filepath}"
		if ($__process -ne 0) {
			OS-Print-Status error "copy failed."
			return 1
		}

		$__process = FS-Copy-File "${_target}" "${_filepath}"
		if ($__process -ne 0) {
			OS-Print-Status error "copy failed."
			return 1
		}


		# generate AutomataCI's required RPM spec instructions (INSTALL)
		$__process = FS-Write-File "${_directory}\SPEC_INSTALL" @"
install --directory %{buildroot}/usr/local/lib/${env:PROJECT_SKU}
install -m 0644 lib${env:PROJECT_SKU}.a %{buildroot}/usr/local/lib/${env:PROJECT_SKU}

install --directory %{buildroot}/usr/local/share/doc/lib${env:PROJECT_SKU}/
install -m 0644 copyright %{buildroot}/usr/local/share/doc/lib${env:PROJECT_SKU}/
"@
		if ($__process -ne 0) {
			return 1
		}


		# generate AutomataCI's required RPM spec instructions (FILES)
		$__process = FS-Write-File "${_directory}\SPEC_FILES" @"
/usr/local/lib/${env:PROJECT_SKU}/lib${env:PROJECT_SKU}.a
/usr/local/share/doc/lib${env:PROJECT_SKU}/copyright
"@
		if ($__process -ne 0) {
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
		$_filepath = "${_directory}\BUILD\${env:PROJECT_SKU}"
		OS-Print-Status info "copying ${_target} to ${_filepath}"
		$__process = FS-Make-Housing-Directory "${_filepath}"
		if ($__process -ne 0) {
			OS-Print-Status error "copy failed."
			return 1
		}

		$__process = FS-Copy-File "${_target}" "${_filepath}"
		if ($__process -ne 0) {
			OS-Print-Status error "copy failed."
			return 1
		}


		# generate AutomataCI's required RPM spec instructions (INSTALL)
		$__process = FS-Write-File "${_directory}\SPEC_INSTALL" @"
install --directory %{buildroot}/usr/local/bin
install -m 0755 ${env:PROJECT_SKU} %{buildroot}/usr/local/bin

install --directory %{buildroot}/usr/local/share/doc/${env:PROJECT_SKU}/
install -m 644 copyright %{buildroot}/usr/local/share/doc/${env:PROJECT_SKU}/

install --directory %{buildroot}/usr/local/share/man/man1/
install -m 644 ${env:PROJECT_SKU}.1.gz %{buildroot}/usr/local/share/man/man1/
"@
		if ($__process -ne 0) {
			return 1
		}


		# generate AutomataCI's required RPM spec instructions (FILES)
		$__process = FS-Write-File "${_directory}\SPEC_FILES" @"
/usr/local/bin/${env:PROJECT_SKU}
/usr/local/share/doc/${env:PROJECT_SKU}/copyright
/usr/local/share/man/man1/${env:PROJECT_SKU}.1.gz
"@
		if ($__process -ne 0) {
			return 1
		}

		$_package = "${env:PROJECT_SKU}"
	}


	# NOTE: REQUIRED file
	OS-Print-Status info "creating copyright.gz file..."
	$__process = COPYRIGHT-Create-RPM `
		"${_directory}\BUILD\copyright" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\licenses\deb-copyright" `
		${env:PROJECT_SKU} `
		${env:PROJECT_CONTACT_NAME} `
		${env:PROJECT_CONTACT_EMAIL} `
		${env:PROJECT_CONTACT_WEBSITE}
	if ($__process -ne 0) {
		return 1
	}


	# NOTE: REQUIRED file
	OS-Print-Status info "creating man pages file..."
	MANUAL-Create-RPM_Manpage `
		${_directory} `
		${env:PROJECT_SKU} `
		${env:PROJECT_CONTACT_NAME} `
		${env:PROJECT_CONTACT_EMAIL} `
		${env:PROJECT_CONTACT_WEBSITE}
	if ($__process -ne 0) {
		return 1
	}


	# NOTE: OPTIONAL (Comment to turn it off)
	OS-Print-Status info "creating source.repo files..."
	$__process = RPM-Create-Source-Repo `
		"${env:PROJECT_SIMULATE_RELEASE_REPO}" `
		"${_directory}" `
		"${env:PROJECT_GPG_ID}" `
		"${env:PROJECT_STATIC_URL}" `
		"${env:PROJECT_REPREPRO_CODENAME}" `
		"${env:PROJECT_DEBIAN_DISTRIBUTION}" `
		"${_gpg_keyring}"
	if ($__process -ne 0) {
		return 1
	}


	# WARNING: THIS REQUIRED FILE MUST BE THE LAST ONE
	OS-Print-Status info "creating spec file..."
	RPM-Create-Spec `
		"${_directory}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}" `
		"${_package}" `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_CADENCE}" `
		"${env:PROJECT_PITCH}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_LICENSE}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\docs\ABSTRACTS.txt"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
