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
. "${env:LIBS_AUTOMATACI}\services\compilers\go.ps1"




# execute
$null = I18N-Activate-Environment
$___process = GO-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$__report_location = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\go-test-report"
$__profile_location = "${__report_location}\test-profile.txt"
$__coverage_filepath = "${__report_location}\test-coverage.html"


$null = I18N-Prepare "${__report_location}"
$___process = FS-Remake-Directory "${__report_location}"
if ($___process -ne 0) {
	$null = I18N-Prepare-Failed
	return 1
}
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}/${env:PROJECT_GO}"


$null = I18N-Run-Test-Coverage
$__arguments = "test -timeout 14400s " `
		+ "-coverprofile `"${__profile_location}`" " `
		+ "-race " `
		+ "-v " `
		+ ".\..."
$___process = OS-Exec "go" "${__arguments}"
if ($___process -ne 0) {
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable -Name __current_path
	$null = I18N-Run-Failed
	return 1
}


$null = I18N-Processing-Test-Coverage
$__arguments =  "tool cover -html=`"${__profile_location}`" -o `"${__coverage_filepath}`""
$___process = OS-Exec "go" "${__arguments}"
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
