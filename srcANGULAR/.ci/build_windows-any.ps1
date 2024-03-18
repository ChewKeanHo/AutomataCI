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
. "${env:LIBS_AUTOMATACI}\services\compilers\angular.ps1"




# execute
$__placeholders = @(
	"${env:PROJECT_SKU}-docs_any-any"
)


$null = FS-Remake-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"


$null = I18N-Activate-Environment
$___process = ANGULAR-Is-Available
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$null = I18N-Build "${env:PROJECT_ANGULAR}"
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_ANGULAR}"
$___process = ANGULAR-Build
$null = Set-Location "${__current_path}"
$null = Remove-Variable __current_path
if ($___process -ne 0) {
	$null = I18N-Build-Failed
	return 1
}




# placeholding flag files
foreach ($__line in $__placeholders) {
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		continue
	}


	# build the file
	$__file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__line}"
	$null = I18N-Build "${__line}"
	$null = FS-Remove-Silently "${__file}"
	$___process = FS-Touch-File "${__file}"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed
		return 1
	}
}




# compose documentations




# report status
return 0
