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

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-functions_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-deb_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-rpm_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-docker_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-pypi_windows-any.ps1"




# execute
$__process = RELEASE-Initiate
if ($__process -ne 0) {
	return 1
}


$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\${env:PROJECT_PATH_CI}"
$__recipe = "${__recipe}\release_windows-any.ps1"
$__process = FS-Is-File "${__recipe}"
if ($__process -eq 0) {
	OS-Print-Status info "Baseline source detected. Parsing job recipe: ${__recipe}"
	$__process = . "${__recipe}"
	if ($__process -ne 0) {
		OS-Print-Status error "Parse failed."
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\release_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "Python tech detected. Parsing job recipe: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Parse failed."
			return 1
		}
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_GO}))) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_GO}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\release_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "Go tech detected. Parsing job recipe: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Parse failed."
			return 1
		}
	}
}


$__process = OS-Is-Command-Available "RELEASE-Run-Pre-Processors"
if ($__process -eq 0) {
	$__process = RELEASE-Run-Pre-Processors
	if ($__process -ne 0) {
		return 1
	}
}


$STATIC_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\${env:PROJECT_STATIC_REPO_DIRECTORY}"


$__process = RELEASE-Run-Release-Repo-Setup
if ($__process -ne 0) {
	return 1
}


foreach ($TARGET in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}")) {
	$TARGET = $TARGET.FullName
	OS-Print-Status info "processing ${TARGET}"

	$__process = RELEASE-Run-DEB `
		"$TARGET" `
		"$STATIC_REPO" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = RELEASE-Run-RPM `
		"$TARGET" `
		"$STATIC_REPO" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = RELEASE-Run-DOCKER `
		"$TARGET" `
		"$STATIC_REPO" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = RELEASE-Run-PYPI `
		"$TARGET" `
		"$STATIC_REPO" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	if ($__process -ne 0) {
		return 1
	}
}


$__process = RELEASE-Run-Checksum-Seal "$STATIC_REPO"
if ($__process -ne 0) {
	return 1
}


$__process = OS-Is-Command-Available "RELEASE-Run-Post-Processors"
if ($__process -eq 0) {
	$__process = RELEASE-Run-Post-Processors
	if ($__process -ne 0) {
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_SIMULATE_RELEASE_REPO}))) {
	OS-Print-Status warning "Simulating release repo conclusion..."
	OS-Print-Status warning "Simulating changelog conclusion..."
} else {
	$__process = RELEASE-Run-Release-Repo-Conclude
	if ($__process -ne 0) {
		return 1
	}


	$__process = RELEASE-Run-Changelog-Conclude
	if ($__process -ne 0) {
		return 1
	}
}




# report status
OS-Print-Status success "`n"
return 0
