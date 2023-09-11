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
IF (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
        Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
        exit 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\versioners\git.ps1"

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_release-deb_unix-any.ps1"




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
	exit 1
}




# source tech-specific functions
if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\release_windows-any.ps1"
	OS-Print-Status info "Python technology detected. Parsing job recipe: ${__recipe}"

	$__process = FS-Is-File "${__recipe}"
	if ($__process -ne 0) {
		OS-Print-Status error "Parse failed - missing file."
		exit 1
	}

	. "${__recipe}"
	if (-not $?) {
		exit 1
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
	OS-Print-Status info "processing ${TARGET}"

	$__process = RELEASE-Run-DEB `
		"$TARGET" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	if ($__process -ne 0) {
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




# use default response since there is no localized CI jobs
OS-Print-Status success ""
exit 0
