# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\angular.ps1"




# execute
$null = I18N-Activate-Environment
$___process = ANGULAR-Is-Available
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$null = I18N-Import-Dependencies
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_ANGULAR}"
$___process = OS-Exec "npm" "install"
$null = Set-Location "${__current_path}"
$null = Remove-Variable -Name __current_path
if ($___process -ne 0) {
	$null = I18N-Import-Failed
	return 1
}




# return status
return 0
