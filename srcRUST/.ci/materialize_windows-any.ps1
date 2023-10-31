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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\rust.ps1"




# safety checking control surfaces
OS-Print-Status info "activating local environment..."
$__process = RUST-Activate-Local-Environment
if ($__process -ne 0) {
	OS-Print-Status error "activation failed."
	return 1
}




# build output binary file
OS-Print-Status info "configuring build settings..."
$__target = Rust-Get-Build-Target "${env:PROJECT_OS}" "${env:PROJECT_ARCH}"
$__filename = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\rust-${__filename}"

if ([string]::IsNullOrEmpty($__target)) {
	OS-Print-Status error "configure failed."
	return 1
}




# building target
OS-Print-Status info "building ${__filename}..."
$null = FS-Remove-Silently "${__workspace}"

$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}"
$__arguments = "build " `
	+ "--release " `
	+ "--target-dir `"${__workspace}`" " `
	+ "--target `"${__target}`" "
$__process = OS-Exec "cargo" "${__arguments}"
$null = Set-Location "${__current_path}"
$null = Remove-Variable __current_path
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# exporting executable
$__source = "${__workspace}\${__target}\release\${env:PROJECT_SKU}.exe"
$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}\${env:PROJECT_SKU}.exe"
OS-Print-Status info "exporting ${__source} to ${__dest}"
$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}"
$null = FS-Remove-Silently "${__dest}"
$__process = FS-Move "${__source}" "${__dest}"
if ($__process -ne 0) {
	OS-Print-Status error "export failed."
	return 1
}




# report status
return 0
