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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Run-RESEARCH {
	param(
		[string]$__target
	)


	# validate input
	$___process = FS-Is-Target-A-PDF "${__target}"
	if ($___process -ne 0) {
		return 0
	}

	if ($($__target -replace "^.*${env:PROJECT_RESEARCH_IDENTIFIER}") -eq "${__target}") {
		return 0 # not a research paper
	}


	# execute
	$null = I18N-Publish "RESEARCH"
	if ($(OS-Is-Run-Simulated) -ne 0) {
		$__dest = "PAPER.pdf"
		$null = I18N-Publish "${__dest}"
		$__dest = "${env:PROJECT_PATH_ROOT}\${__dest}"
		$___process = FS-Copy-File "${__target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Publish-Failed
			return 1
		}
	} else {
		# always simulate in case of error or mishaps before any point of no return
		$null = I18N-Simulate-Publish "RESEARCH"
	}


	# report status
	return 0
}
