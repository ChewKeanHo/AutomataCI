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
. "${env:LIBS_AUTOMATACI}\services\compilers\python.ps1"




# execute
$null = I18N-Activate-Environment
$___process = PYTHON-Activate-VENV
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$__report_location = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\python-test-report"


$null = I18N-Prepare "${__report_location}"
$___process = FS-Remake-Directory "${__report_location}"
if ($___process -ne 0) {
	$null = I18N-Prepare-Failed
	return 1
}


$null = I18N-Run-Test-Coverage
$__argument = "-m coverage run " `
	+ "--data-file=`"${__report_location}\.coverage`" " `
	+ "-m unittest discover " `
	+ "-s `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}`" " `
	+ "-p '*_test.py'"
$___process = OS-Exec python "${__argument}"
if ($___process -ne 0) {
	$null = I18N-Run-Failed
	return 1
}


$null = I18N-Processing-Test-Coverage
$__argument = "-m coverage html " `
	+ "--data-file=`"${__report_location}\.coverage`" " `
	+ "--directory=`"${__report_location}`""
$___process = OS-Exec python "${__argument}"
if ($___process -ne 0) {
	$null = I18N-Processing-Failed
	return 1
}




# report status
return 0
