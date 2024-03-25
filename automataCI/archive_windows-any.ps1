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

. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# validate dependency
$null = I18N-Check "TAR"
$___process = TAR-Is-Available
if ($___process -ne 0) {
	$null = I18N-Check-Failed
	return 1
}




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

	if ("${__line}" -eq "${env:PROJECT_PATH_ROOT}\") {
		continue
	}

	$null = FS-Make-Directory "${__line}"
}
$null = Set-Location "${env:PROJECT_PATH_ROOT}"




# package build
$___artifact_build = "${env:PROJECT_PATH_ROOT}\artifact-build_${env:PROJECT_OS}-${env:PROJECT_ARCH}.tar.gz"
$null = I18N-Archive "${___artifact_build}"
$null = FS-Remove-Silently "${___artifact_build}"
$___arguments = ".\${env:PROJECT_PATH_BUILD}" `
	+ " .\${env:PROJECT_PATH_LOG}" `
	+ " .\${env:PROJECT_PATH_PKG}" `
	+ " .\${env:PROJECT_PATH_DOCS}"
$null = OS-Exec "tar" "czvf ${___artifact_build} ${___arguments}"




# package workspace
$___artifact_workspace = "${env:PROJECT_PATH_ROOT}\artifact-workspace_${env:PROJECT_OS}-${env:PROJECT_ARCH}.tar.gz"
$null = I18N-Archive "${___artifact_workspace}"
$null = FS-Remove-Silently "${___artifact_workspace}"
$___arguments = ".\${env:PROJECT_PATH_BIN}" `
	+ " .\${env:PROJECT_PATH_LIB}" `
	+ " .\${env:PROJECT_PATH_TEMP}" `
	+ " .\${env:PROJECT_PATH_RELEASE}"
$null = OS-Exec "tar" "czvf ${___artifact_workspace} ${___arguments}"




# check existences
$null = I18N-Check "${___artifact_build}"
$___process = FS-Is-File "${___artifact_build}"
if ($___process -ne 0) {
	$null = I18N-Check-Failed
	return 1
}

$null = I18N-Check "${___artifact_workspace}"
$___process = FS-Is-File "${___artifact_workspace}"
if ($___process -ne 0) {
	$null = I18N-Check-Failed
	return 1
}




# report status
$null = I18N-Run-Successful
return 0
