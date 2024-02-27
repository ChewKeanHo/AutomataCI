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
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\docker.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\installer.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\msi.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\python.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\chocolatey.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\dotnet.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\reprepro.ps1"




# begin service
$null = I18N-Install "dotnet"
$__process = DOTNET-Setup
if ($__process -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "chocolatey"
$__process = CHOCOLATEY-Setup
if ($__process -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "docker"
$__process = DOCKER-Setup
if ($__process -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "MSI WiX packager"
$__process = MSI-Setup
if ($__process -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "reprepro"
$___process = REPREPRO-Setup
if ($___process -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


if ($(STRINGS-Is-Empty "${env:PROJECT_PYTHON}") -ne 0) {
	$null = I18N-Install "python"
	if ($(PYTHON-Setup) -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_GO}") -ne 0) {
	$null = I18N-Install "go"
	$__process = INSTALLER-Setup-Go
	if ($__process -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if (($(STRINGS-Is-Empty "${env:PROJECT_GO}") -ne 0) -or
	($(STRINGS-Is-Empty "${env:PROJECT_NIM}") -ne 0) -or
	($(STRINGS-Is-Empty "${env:PROJECT_RUST}") -ne 0)) {
	$null = I18N-Install "c"
	$__process = INSTALLER-Setup-C
	if ($__process -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_NIM}") -ne 0) {
	$null = I18N-Install "nim"
	$__process = INSTALLER-Setup-Nim
	if ($__process -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_ANGULAR}") -ne 0) {
	$null = I18N-Install "angular"
	$__process = INSTALLER-Setup-Angular
	if ($__process -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}




# report status
$null = I18N-Run-Successful
return 0
