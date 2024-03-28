# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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

. "${env:LIBS_AUTOMATACI}\services\io\net\http.ps1"
. "${env:LIBS_AUTOMATACI}\services\ai\google.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# execute
$null = I18N-Activate-Environment
$___process = HTTP-Is-Available
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$null = I18N-Run "${env:PROJECT_GOOGLEAI}"
$___response = GOOGLEAI-Gemini-Query-Text-To-Text "Hi! Are you Gemini?"


# parse json if available
if ($(STRINGS-Is-Empty "${___response}") -ne 0) {
	$___response = "$($___response `
				| ConvertFrom-Json `
				| Select-Object `
					-ErrorAction SilentlyContinue `
					-ExpandProperty candidates[0].content.parts[0].text
	)"
}

$null = Write-Host "${___response}"
$null = I18N-Newline




# report status
return 0
