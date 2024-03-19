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
. "${env:LIBS_AUTOMATACI}\services\compilers\c.ps1"




# execute
$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}"
$null = I18N-Prepare "${___source}"
$___arguments = "$(C-Get-Strict-Settings)"
switch ("${env:PROJECT_OS}") {
"darwin" {
	$___arguments = "${___arguments} -fPIC"
} default {
	$___arguments = "${___arguments} -pie -fPIE"
}}


$null = I18N-Run-Test
$___process = C-Test "${___source}" "${env:PROJECT_OS}" "${env:PROJECT_ARCH}" "${___arguments}"
switch ("${___process}") {
{ $_ -in "0", "10" } {
	# accepted
} default {
	$null = I18N-Run-Failed
	return 1
}}




# report status
return 0
