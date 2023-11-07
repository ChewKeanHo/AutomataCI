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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\msi.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\chocolatey.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\dotnet.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\microsoft.ps1"




# begin service
OS-Print-Status info "Installing DotNET..."
$__process = DOTNET-Setup
if ($__process -ne 0) {
	OS-Print-Status error "install failed."
	return 1
}


OS-Print-Status info "Installing choco..."
$__process = CHOCOLATEY-Setup
if ($__process -ne 0) {
	OS-Print-Status error "install failed."
	return 1
}


OS-Print-Status info "Installing version 14.00 Microsoft C++ Redistributable..."
$__process = MICROSOFT-Setup-VCLibs "14.00"
if ($__process -ne 0) {
	OS-Print-Status error "install failed."
	return 1
}

OS-Print-Status info "Installing version 2.7.3 Microsoft UI Xaml..."
$__process = MICROSOFT-Setup-UIXAML "2.7.3"
if ($__process -ne 0) {
	OS-Print-Status error "install failed."
	return 1
}

OS-Print-Status info "Installing winget..."
$__process = MICROSOFT-Setup-WinGet
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


OS-Print-Status info "Installing MSI WiX packager..."
$__process = MSI-Setup
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


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
	OS-Print-Status info "Installing python..."
	$__process = INSTALLER-Setup-Python
	if ($__process -ne 0) {
		OS-Print-Status error "install failed."
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_GO}))) {
	OS-Print-Status info "Installing go..."
	$__process = INSTALLER-Setup-Go
	if ($__process -ne 0) {
		OS-Print-Status error "install failed."
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_C})) -or
	(-not ([string]::IsNullOrEmpty(${env:PROJECT_NIM}))) -or
	(-not ([string]::IsNullOrEmpty(${env:PROJECT_RUST})))) {
	OS-Print-Status info "Installing c..."
	$__process = INSTALLER-Setup-C
	if ($__process -ne 0) {
		OS-Print-Status error "install failed."
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_NIM}))) {
	OS-Print-Status info "Installing nim..."
	$__process = INSTALLER-Setup-Nim
	if ($__process -ne 0) {
		OS-Print-Status error "install failed."
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_ANGULAR}))) {
	OS-Print-Status info "Installing angular..."
	$__process = INSTALLER-Setup-Angular
	if ($__process -ne 0) {
		OS-Print-Status error "install failed."
		return 1
	}
}




# report status
OS-Print-Status success "`n"
return 0
