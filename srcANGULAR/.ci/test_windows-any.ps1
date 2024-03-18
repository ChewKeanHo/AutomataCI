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

. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\angular.ps1"




# execute
$null = I18N-Activate-Environment
$___process = ANGULAR-Is-Available
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$null = I18N-Run-Test-Coverage
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_ANGULAR}"
if ($(OS-Is-Run-Simulated) -eq 0) {
	$null = I18N-Simulate-Testing
	return 0
} else {
	$___browser = Get-Command "chrome.exe" -ErrorAction SilentlyContinue
	if ($(STRINGS-Is-Empty "${___browser}") -eq 0) {
		$null = I18N-Run-Failed
		return 1
	}
	$env:CHROME_BIN = $___browser

	$___process = ANGULAR-Test
	if ($___process -ne 0) {
		$null = I18N-Run-Failed
		return 1
	}
}
$null = Set-Location "${__current_path}"
$null = Remove-Variable __current_path


$null = I18N-Processing-Test-Coverage
$___source = "${env:PROJECT_PATH_ROOT}/${env:PROJECT_ANGULAR}/coverage"
$___dest = "${env:PROJECT_PATH_ROOT}/${env:PROJECT_PATH_LOG}/angular-test-report"
$___process = FS-Is-Directory "${___source}"
if ($___process -ne 0) {
	$null = I18N-Processing-Failed
	return 1
}

$null = FS-Remove-Silently "${___dest}"
$null = FS-Make-Housing-Directory "${___dest}"
$___process = FS-Move "${___source}" "${___dest}"
if ($___process -ne 0) {
	$null = I18N-Processing-Failed
	return 1
}




# report status
return 0
