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

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# execute tech specific CI jobs if available
foreach ($__target in @(
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}"
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}"
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_DOCS}"
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LIB}"
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}"
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}"
)) {
	if ("${__target}" -eq ${env:PROJECT_PATH_ROOT}) {
		continue
	}

	if ("${__target}" -eq "${env:PROJECT_PATH_ROOT}/") {
		continue
	}

	$null = I18N-Purge "${__target}"
	$null = FS-Remove-Silently "${__target}"
}




# clean archive artifacts
$null = Set-Location -Path "${PROJECT_PATH_ROOT}"
$null = Remove-Item -Path "artifact-*.*" -ErrorAction SilentlyContinue




# report status
$null = I18N-Run-Successful
return 0
