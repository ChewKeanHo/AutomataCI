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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\time.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\citation.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function PACKAGE-Run-CITATION {
	param(
		[string]$__citation_cff
	)

	# execute
	$null = I18N-Create "${__citation_cff}"
	$___process = CITATION-Build `
		"${__citation_cff}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs\ABSTRACTS.txt" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs\CITATIONS.yml" `
		"${env:PROJECT_CITATION}" `
		"${env:PROJECT_CITATION_TYPE}" `
		"$(TIME-Format-Date-ISO8601 "$(TIME-Now)")" `
		"${env:PROJECT_NAME}" `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_LICENSE}" `
		"${env:PROJECT_SOURCE_URL}" `
		"${env:PROJECT_SOURCE_URL}" `
		"${env:PROJECT_STATIC_URL}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_CONTACT_EMAIL}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
