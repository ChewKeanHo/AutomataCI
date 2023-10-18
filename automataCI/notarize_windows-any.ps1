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
	Write-Error "[ ERROR ] - Please run me from ci.cmd instead!\n"
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"




# source locally provided functions
$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\${env:PROJECT_PATH_CI}"
$__recipe = "${__recipe}\notarize_windows-any.ps1"
$__process = FS-Is-File "${__recipe}"
if ($__process -eq 0) {
	OS-Print-Status info "sourcing content assembling functions: ${__recipe}"
	$__process = . "${__recipe}"
	if ($__process -ne 0) {
		OS-Print-Status error "Source failed."
		return 1
	}
}




# source from Python and overrides existing
if (-not [string]::IsNullOrEmpty(${env:PROJECT_PYTHON})) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\notarize_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "sourcing Python content assembling functions: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Source failed."
			return 1
		}
	}
}




# source from Go and overrides existing
if (-not [string]::IsNullOrEmpty(${env:PROJECT_GO})) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_GO}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\notarize_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "sourcing Go content assembling functions: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Source failed."
			return 1
		}
	}
}




# source from C and overrides existing
if (-not [string]::IsNullOrEmpty(${env:PROJECT_C})) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\notarize_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "sourcing C content assembling functions: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Source failed."
			return 1
		}
	}
}




# source from Nim and overrides existing
if (-not [string]::IsNullOrEmpty(${env:PROJECT_NIM})) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\notarize_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "sourcing Nim content assembling functions: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Source failed."
			return 1
		}
	}
}




# begin notarize
foreach ($i in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}")) {
	$i = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${i}"
	$__process = FS-Is-Directory "$i"
	if ($__process -eq 0) {
		continue
	}

	$__process = FS-Is-File "$i"
	if ($__process -ne 0) {
		continue
	}


	# parse build candidate
	OS-Print-Status info "detected $i"
	$TARGET_FILENAME = Split-Path -Leaf $i
	$TARGET_FILENAME = $TARGET_FILENAME -replace `
		(Join-Path $env:PROJECT_PATH_ROOT $env:PROJECT_PATH_BUILD), ""
	$TARGET_FILENAME = $TARGET_FILENAME -replace "\..*$"
	$TARGET_OS = $TARGET_FILENAME -replace ".*_"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "_.*"
	$TARGET_ARCH = $TARGET_OS -replace ".*-"
	$TARGET_OS = $TARGET_OS -replace "-.*"

	if ([string]::IsNullOrEmpty($TARGET_OS) -or
		[string]::IsNullOrEmpty($TARGET_ARCH) -or
		[string]::IsNullOrEmpty($TARGET_FILENAME)) {
		OS-Print-Status warning "failed to parse file. Skipping."
		continue
	}

	$__process = STRINGS-Has-Prefix "${env:PROJECT_SKU}" "$TARGET_FILENAME"
	if ($__process -ne 0) {
		OS-Print-Status warning "incompatible file. Skipping."
		continue
	}

	$__process = OS-Is-Command-Available "NOTARY-Certify"
	if ($__process -eq 0) {
		$__process = NOTARY-Certify `
			"$i" `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}" `
			"$TARGET_FILENAME" `
			"$TARGET_OS" `
			"$TARGET_ARCH"
		switch ($__process) {
		12 {
			OS-Print-Status warning "simulating successful notarization..."
		} 11 {
			OS-Print-Status warning "notarization unavailable. Skipping..."
		} 10 {
			OS-Print-Status warning "notarization is not applicable. Skipping..."
		} 0 {
			OS-Print-Status success "`n"
		} default {
			OS-Print-Status error "notarization failed."
			return 1
		}}
	} else {
		OS-Print-Status warning "NOTARY-Certify is unavailable. Skipping..."
	}
}




# report status
return 0
