# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\rust.ps1"




# safety checking control surfaces
$null = I18N-Activate-Environment
$___process = RUST-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}




# execute
$__report_location = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\rust-test-report"
$__target = Rust-Get-Build-Target "${env:PROJECT_OS}" "${env:PROJECT_ARCH}"
$__filename = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\rust-test-${__filename}"


$null = I18N-Prepare "${__report_location}"
$___process = FS-Remake-Directory "${__report_location}"
if ($___process -ne 0) {
	$null = I18N-Prepare-Failed
	return 1
}
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}"


$null = I18N-Run-Test-Coverage
$env:RUSTFLAGS = "-C instrument-coverage=all"
$___process = OS-Exec "cargo" "test --verbose --target-dir `"${__workspace}`""
foreach ($__file in (Get-ChildItem -Filter "*.profraw")) {
	$null = FS-Move $__file.FullName "${__workspace}"
}

if ($___process -ne 0) {
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable -Name __current_path
	$null = I18N-Run-Failed
	return 1
}


$null = I18N-Processing-Test-Coverage
$__arguments = "${__workspace} " `
	+ "--source-dir `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}`" " `
	+ "--binary-path `"${__workspace}\debug`" " `
	+ "--output-types `"html`" " `
	+ "--branch " `
	+ "--ignore-not-existing " `
	+ "--output-path `"${__report_location}`" "
$___process = OS-Exec "grcov" "${__arguments}"
if ($___process -ne 0) {
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable -Name __current_path
	$null = I18N-Processing-Failed
	return 1
}


$null = Set-Location "${__current_path}"
$null = Remove-Variable -Name __current_path




# report status
return 0
