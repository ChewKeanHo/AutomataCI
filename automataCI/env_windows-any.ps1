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

. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\net\http.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\appimage.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\angular.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\c.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\docker.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\go.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\libreoffice.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\msi.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\nim.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\node.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\python.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\chocolatey.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\dotnet.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\github.ps1"




# begin service
$null = I18N-Install "GITHUB ACTIONS"
if ($(GITHUB-Setup-Actions) -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "DOTNET"
if ($(DOTNET-Setup) -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "CHOCOLATEY"
if ($(CHOCOLATEY-Setup) -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "CURL"
if ($(HTTP-Setup) -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "DOCKER"
if ($(DOCKER-Setup) -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "APPIMAGE"
if ($(APPIMAGE-Setup) -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


$null = I18N-Install "MSI (WIX)"
if ($(MSI-Setup) -ne 0) {
	$null = I18N-Install-Failed
	return 1
}


if ($(STRINGS-Is-Empty "${env:PROJECT_PYTHON}") -ne 0) {
	$null = I18N-Install "PYTHON"
	if ($(PYTHON-Setup) -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_GO}") -ne 0) {
	$null = I18N-Install "GO"
	if ($(GO-Setup) -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if (($(STRINGS-Is-Empty "${env:PROJECT_C}") -ne 0) -or
	($(STRINGS-Is-Empty "${env:PROJECT_GO}") -ne 0) -or
	($(STRINGS-Is-Empty "${env:PROJECT_NIM}") -ne 0) -or
	($(STRINGS-Is-Empty "${env:PROJECT_RUST}") -ne 0)) {
	$null = I18N-Install "C/C++"
	if ($(C-Setup) -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_NIM}") -ne 0) {
	$null = I18N-Install "NIM"
	if ($(NIM-Setup) -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if (($(STRINGS-Is-Empty "${env:PROJECT_NODE}") -ne 0) -or
	($(STRINGS-Is-Empty "${env:PROJECT_ANGULAR}") -ne 0)) {
	$null = I18N-Install "NODE"
	if ($(NODE-Setup) -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_ANGULAR}") -ne 0) {
	$null = I18N-Install "ANGULAR"
	if ($(ANGULAR-Setup) -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}


if (($(STRINGS-Is-Empty "${env:PROJECT_LIBREOFFICE}") -ne 0) -or
	($(STRINGS-Is-Empty "${env:PROJECT_BOOK}") -ne 0) -or
	($(STRINGS-Is-Empty "${env:PROJECT_RESEARCH}") -ne 0)) {
	$null = I18N-Install "LIBREOFFICE"
	if ($(LIBREOFFICE-Setup) -ne 0) {
		$null = I18N-Install-Failed
		return 1
	}
}




# report status
$null = I18N-Run-Successful
return 0
