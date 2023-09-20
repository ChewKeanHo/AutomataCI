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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\installer.ps1"




# begin service
OS-Print-Status info "Installing choco..."
$__process = INSTALLER-Setup
if ($__process -ne 0) {
	OS-Print-Status error "install failed."
	return 1
}


OS-Print-Status info "Installing curl..."
$__process = INSTALLER-Setup-Curl
if ($__process -ne 0) {
	OS-Print-Status error "install failed."
	return 1
}


OS-Print-Status info "Installing docker..."
$__process = INSTALLER-Setup-Docker
if ($__process -ne 0) {
	OS-Print-Status error "install failed."
	return 1
}


OS-Print-Status info "Installing reprepro..."
$__process = INSTALLER-Setup-Reprepro
if ($__process -ne 0) {
	OS-Print-Status error "install failed."
	return 1
}


OS-Print-Status info "Setting up release repo..."
if (Test-Path -PathType Container -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}") {
	# ACCEPTED - do nothing
} elseif (Test-Path -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}") {
	OS-Print-Status error "setup failed - target '${env:PROJECT_PATH_RELEASE}' is a file!"
	return 1
}

$__process = INSTALLER-Setup-Release-Repo `
	"${env:PROJECT_PATH_ROOT}" `
	"${env:PROJECT_PATH_RELEASE}" `
	"$(Get-Location)" `
	"${env:PROJECT_STATIC_REPO}" `
	"${env:PROJECT_SIMULATE_RELEASE_REPO}"
if ($__process -ne 0) {
	OS-Print-Status error "setup failed."
	return 1
}




# report status
OS-Print-Status success "`n"
return 0
