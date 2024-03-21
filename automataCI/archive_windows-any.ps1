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
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# execute tech specific CI jobs if available
foreach ($__line in @(
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
	if ("${__line}" -eq ${env:PROJECT_PATH_ROOT}) {
		continue
	}

	if ("${__line}" -eq "${env:PROJECT_PATH_ROOT}/") {
		continue
	}

	$null = FS-Make-Directory "${__line}"
}
$null = Set-Location "${env:PROJECT_PATH_ROOT}"




# package build
$___target = "artifact-build_${env:PROJECT_OS}-${env:PROJECT_ARCH}.zip"
$null = I18N-Archive "${___target}"
$null = FS-Remove-Silently "${___target}"
foreach ($__line in @(
	"${env:PROJECT_PATH_BUILD}"
	"${env:PROJECT_PATH_LOG}"
	"${env:PROJECT_PATH_PKG}"
	"${env:PROJECT_PATH_DOCS}"
)) {
	$null = ZIP-Create "${___target}" "${__line}"
}




# package workspace
$___target = "artifact-workspace_${env:PROJECT_OS}-${env:PROJECT_ARCH}.zip"
$null = I18N-Archive "${___target}"
$null = FS-Remove-Silently "${___target}"
foreach ($__line in @(
	"${env:PROJECT_PATH_BIN}"
	"${env:PROJECT_PATH_LIB}"
	"${env:PROJECT_PATH_TEMP}"
	"${env:PROJECT_PATH_RELEASE}"
)) {
	$null = ZIP-Create "${___target}" "${__line}"
}




# report status
$null = I18N-Run-Successful
return 0
