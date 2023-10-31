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




# execute
$__report_location = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\rust-test-report"
$__target = Rust-Get-Build-Target "${env:PROJECT_OS}" "${env:PROJECT_ARCH}"
$__filename = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\rust-test-${__filename}"


OS-Print-Status info "preparing report vault: ${__report_location}"
$__process = FS-Remake-Directory "${__report_location}"
if ($__process -ne 0) {
	OS-Print-Status error "preparation failed."
	return 1
}
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}"


OS-Print-Status info "executing all tests with coverage..."
$env:RUSTFLAGS = "-C instrument-coverage=all"
$__process = OS-Exec "cargo" "test --verbose --target-dir `"${__workspace}`""
foreach ($__file in (Get-ChildItem -Filter "*.profraw")) {
	$null = FS-Move $__file.FullName "${__workspace}"
}

if ($__process -ne 0) {
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable -Name __current_path
	OS-Print-Status error "test executions failed."
	return 1
}


OS-Print-Status info "processing all coverage profile data..."
$__arguments = "${__workspace} " `
	+ "--source-dir `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}`" " `
	+ "--binary-path `"${__workspace}\debug`" " `
	+ "--output-types `"html`" " `
	+ "--branch " `
	+ "--ignore-not-existing " `
	+ "--output-path `"${__report_location}`" "
$__process = OS-Exec "grcov" "${__arguments}"
if ($__process -ne 0) {
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable -Name __current_path
	OS-Print-Status error "test executions failed."
	return 1
}


$null = Set-Location "${__current_path}"
$null = Remove-Variable -Name __current_path




# report status
return 0
