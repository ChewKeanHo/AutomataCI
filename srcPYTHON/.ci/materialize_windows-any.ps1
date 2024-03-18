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
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\python.ps1"




# execute
$null = I18N-Activate-Environment
$___process = PYTHON-Activate-VENV
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$null = I18N-Check "PYINSTALLER"
$___process = OS-Is-Command-Available "pyinstaller"
if ($___process -ne 0) {
	$null = I18N-Check-Failed
	return 1
}


$null = I18N-Check "PDOC"
$___process = OS-Is-Command-Available "pdoc"
if ($___process -ne 0) {
	$null = I18N-Check-Failed
	return 1
}




# build output binary file
switch (${env:PROJECT_OS}) {
windows {
	$__source = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}.exe"
} default {
	$__source = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
}}

$null = I18N-Build "${__source}"
$__argument = "--noconfirm " `
	+ "--onefile " `
	+ "--clean " `
	+ "--distpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}`" " `
	+ "--workpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}`" " `
	+ "--specpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}`" " `
	+ "--name `"${__source}`" " `
	+ "--hidden-import=main " `
	+ "`"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\main.py`""
$___process = OS-Exec "pyinstaller" "${__argument}"
if ($___process -ne 0) {
	$null = I18N-Build-Failed
	return 1
}




# exporting executable
$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__source}"
$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}\${env:PROJECT_SKU}"
if ("${env:PROJECT_OS}" -eq "windows") {
	$__dest = "${__dest}.exe"
}
$null = I18N-Export "${__source}" "${__dest}"
$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}"
$null = FS-Remove-Silently "${__dest}"
$___process = FS-Move "${__source}" "${__dest}"
if ($___process -ne 0) {
	$null = I18N-Export-Failed
	return 1
}




# report status
return 0
