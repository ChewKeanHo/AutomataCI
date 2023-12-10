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

. "${env:LIBS_AUTOMATACI}\services\compilers\docker.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\installer.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\msi.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\chocolatey.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\dotnet.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-env.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




# begin service
$null = I18N-Status-Print-Env-Install "dotnet"
$__process = DOTNET-Setup
if ($__process -ne 0) {
	$null = I18N-Status-Print-Env-Install-Failed
	return 1
}


$null = I18N-Status-Print-Env-Install "chocolatey"
$__process = CHOCOLATEY-Setup
if ($__process -ne 0) {
	$null = I18N-Status-Print-Env-Install-Failed
	return 1
}


$null = I18N-Status-Print-Env-Install "docker"
$__process = DOCKER-Setup
if ($__process -ne 0) {
	$null = I18N-Status-Print-Env-Install-Failed
	return 1
}


$null = I18N-Status-Print-Env-Install "MSI WiX packager"
$__process = MSI-Setup
if ($__process -ne 0) {
	$null = I18N-Status-Print-Env-Install-Failed
	return 1
}


$null = I18N-Status-Print-Env-Install "reprepro"
$__process = INSTALLER-Setup-Reprepro
if ($__process -ne 0) {
	$null = I18N-Status-Print-Env-Install-Failed
	return 1
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
	$null = I18N-Status-Print-Env-Install "python"
	$__process = INSTALLER-Setup-Python
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Env-Install-Failed
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_GO}))) {
	$null = I18N-Status-Print-Env-Install "go"
	$__process = INSTALLER-Setup-Go
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Env-Install-Failed
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_C})) -or
	(-not ([string]::IsNullOrEmpty(${env:PROJECT_NIM}))) -or
	(-not ([string]::IsNullOrEmpty(${env:PROJECT_RUST})))) {
	$null = I18N-Status-Print-Env-Install "c"
	$__process = INSTALLER-Setup-C
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Env-Install-Failed
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_NIM}))) {
	$null = I18N-Status-Print-Env-Install "nim"
	$__process = INSTALLER-Setup-Nim
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Env-Install-Failed
		return 1
	}
}


if (-not ([string]::IsNullOrEmpty(${env:PROJECT_ANGULAR}))) {
	$null = I18N-Status-Print-Env-Install "angular"
	$__process = INSTALLER-Setup-Angular
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Env-Install-Failed
		return 1
	}
}




# report status
$null = I18N-Status-Print-Run-Successful
return 0
