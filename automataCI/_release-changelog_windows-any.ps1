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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\changelog.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Conclude-CHANGELOG {
	# execute
	$null = I18N-Conclude "${env:PROJECT_VERSION} CHANGELOG"
	if ($(OS-Is-Run-Simulated) -ne 0) {
		$___process = CHANGELOG-Seal `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\changelog" `
			"${env:PROJECT_VERSION}"
		if ($___process -ne 0) {
			$null = I18N-Conclude-Failed
			return 1
		}
	} else {
		# always simulate in case of error or mishaps before any point of no return
		$null = I18N-Simulate-Conclude "${env:PROJECT_VERSION} CHANGELOG"
	}


	# return status
	return 0
}
