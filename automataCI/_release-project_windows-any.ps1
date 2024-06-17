# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                  http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\changelog.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Conclude-PROJECT {
	# execute
	$null = I18N-Conclude "${env:PROJECT_VERSION}"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Conclude "${env:PROJECT_VERSION}"
		return 0
	}

	$___process = FS-Is-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
	if (($___process -eq 0) -and ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -ne 0)) {
		# commit single unified repository
		$null = I18N-Commit "${env:PROJECT_RELEASE_REPO}"
		$__current_path = Get-Location
		$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
		$___process = GIT-Autonomous-Force-Commit `
			"${env:PROJECT_VERSION}" `
			"${env:PROJECT_RELEASE_REPO_KEY}" `
			"${env:PROJECT_RELEASE_REPO_BRANCH}"
		$null = Set-Location "${__current_path}"
		$null = Remove-Variable __current_path
		if ($___process -ne 0) {
			$null = I18N-Commit-Failed
			return 1
		}
	}


	# return status
	return 0
}




function RELEASE-Setup-PROJECT {
	# execute
	$null = I18N-Setup "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
	if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -ne 0) {
		$null = I18N-Setup "${env:PROJECT_RELEASE_REPO}"
		$___process = GIT-Is-Available
		if ($___process -ne 0) {
			$null = I18N-Setup-Failed
			return 1
		}

		$null = FS-Remove-Silently "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
		$__current_path = Get-Location
		$null = Set-Location "${env:PROJECT_PATH_ROOT}"
		$___process = OS-Exec "git" `
			"clone `"${env:PROJECT_RELEASE_REPO}`" `"${env:PROJECT_PATH_RELEASE}`""
		$null = Set-Location "${__current_path}"
		$null = Remove-Variable __current_path
		if ($___process -ne 0) {
			$null = I18N-Setup-Failed
			return 1
		}
	} else {
		$___process = FS-Remake-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
		if ($___process -ne 0) {
			$null = I18N-Setup-Failed
			return 1
		}
	}


	# report status
	return 0
}
