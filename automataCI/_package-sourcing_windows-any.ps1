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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




# source from baseline
$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\${env:PROJECT_PATH_CI}"
$__recipe = "${__recipe}\package_windows-any.ps1"
$__process = FS-Is-File "${__recipe}"
if ($__process -eq 0) {
	OS-Print-Status info "sourcing content assembling functions: ${__recipe}"
	$__process = . "${__recipe}"
	if ($__process -ne 0) {
		OS-Print-Status error "Source failed."
		return
	}
}




# source from Python and overrides existing
if (-not [string]::IsNullOrEmpty(${env:PROJECT_PYTHON})) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\package_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "sourcing Python content assembling functions: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Source failed."
			return
		}
	}
}




# source from Go and overrides existing
if (-not [string]::IsNullOrEmpty(${env:PROJECT_GO})) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_GO}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\package_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "sourcing Go content assembling functions: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Source failed."
			return
		}
	}
}




# source from C and overrides existing
if (-not [string]::IsNullOrEmpty(${env:PROJECT_C})) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\package_windows-any.ps1"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "sourcing C content assembling functions: ${__recipe}"
		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Source failed."
			return
		}
	}
}
