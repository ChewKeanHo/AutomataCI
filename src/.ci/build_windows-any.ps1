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
. "${env:LIBS_AUTOMATACI}\services\io\time.ps1"
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
$__directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\changelog"
$null = I18N-Create "${env:PROJECT_VERSION} DATA CHANGELOG"
$___process = CHANGELOG-Build-DATA-Entry $__directory
if ($___process -ne 0) {
	$null = I18N-Create-Failed
	return 1
}


$null = I18N-Create "${env:PROJECT_VERSION} DEB CHANGELOG"
$___process = CHANGELOG-Build-DEB-Entry `
	"${__directory}" `
	"$env:PROJECT_VERSION" `
	"$env:PROJECT_SKU" `
	"$env:PROJECT_DEB_DISTRIBUTION" `
	"$env:PROJECT_DEB_URGENCY" `
	"$env:PROJECT_CONTACT_NAME" `
	"$env:PROJECT_CONTACT_EMAIL" `
	"$(TIME-Format-Datetime-RFC5322 "$(TIME-Now)")"
if ($___process -ne 0) {
	$null = I18N-Create-Failed
	return 1
}




# report status
return 0
