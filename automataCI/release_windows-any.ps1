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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\checksum\shasum.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\crypto\gpg.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\versioners\git.ps1"

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-deb_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-rpm_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-docker_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-pypi_windows-any.ps1"




# safety check control surfaces
OS-Print-Status info "Checking shasum availability..."
$__process = SHASUM-Is-Available
if ($__process -ne 0) {
	OS-Print-Status error "Check failed."
	return 1
}




# setup release repo
OS-Print-Status info "Setup artifact release repo..."
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}"
$__process = GIT-clone "${env:PROJECT_STATIC_REPO}" "${env:PROJECT_PATH_RELEASE}"
$__current_path = Get-Location
$null = Set-Location "${__current_path}"
$null = Remove-Variable __current_path

if ($__process -eq 2) {
	OS-Print-Status info "Existing directory detected. Skipping..."
} elseif ($__process -ne 0) {
	OS-Print-Status error "Setup failed."
	return 1
}




# source tech-specific functions
if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\release_windows-any.ps1"
	OS-Print-Status info "Python technology detected. Parsing job recipe: ${__recipe}"

	$__process = FS-Is-File "${__recipe}"
	if ($__process -ne 0) {
		OS-Print-Status error "Parse failed - missing file."
		return 1
	}

	$__process = . "${__recipe}"
	if ($__process -ne 0) {
		return 1
	}
}




# run pre-processors
if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
	OS-Print-Status info "running python pre-processing function..."
	$__process = OS-Is-Command-Available "RELEASE-Run-Python-Pre-Processor"
	if ($__process -ne 0) {
		OS-Print-Status error "missing RELEASE-Run-Python-Pre-Processor function."
		return 1
	}

	$__process = RELEASE-Run-Python-Pre-Processor `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
	switch ($__process) {
	10 {
		OS-Print-Status warning "release is not required. Skipping process."
		return 0
	} 0 {
		# accepted
	} Default {
		OS-Print-Status error "pre-processor failed."
		return 1
	}}
}




# loop through each package and publish accordingly
foreach ($TARGET in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}")) {
	$TARGET = $TARGET.FullName
	OS-Print-Status info "processing ${TARGET}"

	$__process = RELEASE-Run-DEB `
		"$TARGET" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = RELEASE-Run-RPM `
		"$TARGET" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = RELEASE-Run-DOCKER `
		"$TARGET" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = RELEASE-Run-PYPI `
		"$TARGET" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	if ($__process -ne 0) {
		return 1
	}
}



# certify all payloads
$__sha256_file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\sha256.txt"
$__sha256_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\sha256.txt"
$__sha512_file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\sha512.txt"
$__sha512_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\sha512.txt"


$null = FS-Remove-Silently "${__sha256_file}"
$null = FS-Remove-Silently "${__sha256_target}"
$null = FS-Remove-Silently "${__sha512_file}"
$null = FS-Remove-Silently "${__sha512_target}"


$__process = GPG-Is-Available "${env:PROJECT_GPG_ID}"
if ($__process -eq 0) {
	foreach ($TARGET in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}")) {
		$TARGET = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${TARGET}"
		if ($TARGET.EndsWith(".asc") {
			continue # it's a gpg cert
		}

		OS-Print-Status info "gpg signing: ${TARGET}"
		FS-Remove-Silently "${TARGET}.asc"
		$__process = GPG-Detach-Sign-File "${TARGET}" "${env:PROJECT_GPG_ID}"
		if ($__process -ne 0) {
			OS-Print-Status error "sign failed."
			return 1
		}
	}

	OS-Print-Status info "exporting GPG public key..."
	$__keyfile = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${env:PROJECT_SKU}.gpg.asc"
	$__process = GPG-Export-Public-Key "${__keyfile}" "${env:PROJECT_GPG_ID}"
	if ($__process -ne 0) {
		OS-Print-Status error "export failed."
		return 1
	}

	$__process = FS-Copy-File "${__keyfile}" "${env:PROJECT_GPG_ID}"
	if ($__process -ne 0) {
		OS-Print-Status error "export failed."
		return 1
	}
}


foreach ($TARGET in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}")) {
	if (-not ([string]::IsNullOrEmpty(${env:PROJECT_RELEASE_SHA256}))) {
		OS-Print-Status info "sha256 checksuming ${TARGET}"
		$__value = SHASUM-Checksum-File $TARGET.FullName "256"
		if ([string]::IsNullOrEmpty(${__value})) {
			OS-Print-Status error "sha256 failed."
			return 1
		}

		FS-Append-File "${__sha256_file}" @"
${__value}  $TARGET
"@
	}

	if (-not ([string]::IsNullOrEmpty(${env:PROJECT_RELEASE_SHA512}))) {
		OS-Print-Status info "sha512 checksuming ${TARGET}"
		$__value = SHASUM-Checksum-File $TARGET.FullName "512"
		if ([string]::IsNullOrEmpty(${__value})) {
			OS-Print-Status error "sha512 failed."
			return 1
		}

		FS-Append-File "${__sha512_file}" @"
${__value}  $TARGET
"@
	}
}


if (Test-Path -Path "${__sha256_file}") {
	OS-Print-Status info "exporting sha256.txt..."
	$__process = FS-Move "${__sha256_file}" "${__sha256_target}"
	if ($__process -ne 0) {
		OS-Print-Status error "export failed."
		return 1
	}
}


if (Test-Path -Path "${__sha512_file}") {
	OS-Print-Status info "exporting sha512.txt..."
	$__process = FS-Move "${__sha512_file}" "${__sha512_target}"
	if ($__process -ne 0) {
		OS-Print-Status error "export failed."
		return 1
	}
}




# run post-processors
if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
	OS-Print-Status info "running python post-processing function..."
	$__process = OS-Is-Command-Available "RELEASE-Run-Python-Post-Processor"
	if ($__process -ne 0) {
		OS-Print-Status error "missing RELEASE-Run-Python-Post-Processor function."
		return 1
	}

	$__process = RELEASE-Run-Python-Post-Processor `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
	switch ($__process) {
	10 {
		# accepted
	} 0 {
		# accepted
	} Default {
		OS-Print-Status error "post-processor failed."
		return 1
	}}
}




# report status
OS-Print-Status success ""
return 0
