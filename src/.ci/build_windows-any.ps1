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
. "${env:LIBS_AUTOMATACI}\services\compilers\changelog.ps1"




# safety checking control surfaces
$null = I18N-Check-Availability "CHANGELOG"
$___process = CHANGELOG-Is-Available
if ($___process -ne 0) {
	$null = I18N-Check-Failed
	return 1
}




# execute
$__file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\changelog"
$null = I18N-Create "${env:PROJECT_VERSION} DATA CHANGELOG"
$___process = CHANGELOG-Build-DATA-Entry $__file
if ($___process -ne 0) {
	$null = I18N-Create-Failed
	return 1
}


$null = I18N-Create "${env:PROJECT_VERSION} DEB CHANGELOG"
$___process = CHANGELOG-Build-DEB-Entry `
	"${__file}" `
	"$env:PROJECT_VERSION" `
	"$env:PROJECT_SKU" `
	"$env:PROJECT_DEBIAN_DISTRIBUTION" `
	"$env:PROJECT_DEBIAN_URGENCY" `
	"$env:PROJECT_CONTACT_NAME" `
	"$env:PROJECT_CONTACT_EMAIL" `
	(Get-Date -Format 'R')
if ($___process -ne 0) {
	$null = I18N-Create-Failed
	return 1
}




# report status
return 0
