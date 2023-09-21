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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\go.ps1"




# safety checking control surfaces
OS-Print-Status info "checking go availability..."
$__process = GO-Is-Available
if ($__process -ne 0) {
	OS-Print-Status error "missing go compiler."
	return 1
}


OS-Print-Status info "activating local environment..."
$__process = GO-Activate-Local-Environment
if ($__process -ne 0) {
	OS-Print-Status error "activation failed."
	return 1
}




# execute
$__report_location = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\go-test-report"
$__profile_location = "${__report_location}\test-profile.txt"
$__coverage_filepath = "${__report_location}\test-coverage.html"


OS-Print-Status info "preparing report vault: ${__report_location}"
$__process = FS-Remake-Directory "${__report_location}"
if ($__process -ne 0) {
	OS-Print-Status error "preparation failed."
	return 1
}
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}/${env:PROJECT_GO}"


OS-Print-Status info "executing all tests with coverage..."
$__arguments = "test -timeout 14400s " `
		+ "-coverprofile `"${__profile_location}`" " `
		+ "-race " `
		+ "-v " `
		+ ".\..."
$__process = OS-Exec "go" $__arguments
if ($__process -ne 0) {
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable -Name __current_path
	OS-Print-Status error "test executions failed."
	return 1
}


OS-Print-Status info "processing test coverage data to html..."
$__arguments =  "tool cover -html=`"${__profile_location}`" -o `"${__coverage_filepath}`""
$__process = OS-Exec "go" $__arguments
if ($__process -ne 0) {
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable -Name __current_path
	OS-Print-Status error "data processing failed."
	return 1
}


$null = Set-Location "${__current_path}"
$null = Remove-Variable -Name __current_path




# report status
return 0