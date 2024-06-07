# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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

. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\node.ps1"




# execute
$null = I18N-Activate-Environment
$___process = NODE-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$null = I18N-Guide-Start-Source "${env:PROJECT_NODE_LOCALIZED}"




# report status
return 0
