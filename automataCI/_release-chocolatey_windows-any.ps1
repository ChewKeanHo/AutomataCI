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
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\chocolatey.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Run-CHOCOLATEY {
	param(
		[string]$___target,
		[string]$___repo
	)


	# validate input
	$___process = CHOCOLATEY-Is-Valid-Nupkg "${___target}"
	if ($___process -ne 0) {
		return 0
	}

	$null = I18N-Export "${___target}"
	if (($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___repo}") -eq 0)) {
		$null = I18N-Export-Failed
		return 1
	}


	# execute
	$___process = CHOCOLATEY-Publish `
		"${___target}" `
		"${___repo}\${env:PROJECT_CHOCOLATEY_DIRECTORY}"
	if ($___process -ne 0) {
		$null = I18N-Export-Failed
		return 1
	}


	# report status
	return 0
}




function RELEASE-Conclude-CHOCOLATEY {
	param(
		[string]$___directory
	)


	# validate input
	$null = I18N-Commit "CHOCOLATEY"
	if ($(STRINGS-Is-Empty "${___directory}") -eq 0) {
		$null = I18N-Commit-Failed
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		$null = I18N-Commit-Failed
		return 1
	}


	# execute
	$__current_path = Get-Location
	$null = Set-Location "${___directory}"
	$___process = GIT-Autonomous-Commit "${env:PROJECT_SKU} ${env:PROJECT_VERSION}"
	if ($___process -ne 0) {
		$null = Set-Location "${__curent_path}"
		$null = Remove-Variable __current_path
		$null = I18N-Commit-Failed
		return 1
	}


	$___process = GIT-Pull-To-Latest
	if ($___process -ne 0) {
		$null = Set-Location "${__curent_path}"
		$null = Remove-Variable __current_path
		$null = I18N-Commit-Failed
		return 1
	}


	$___process = GIT-Push `
		"${env:PROJECT_CHOCOLATEY_REPO_KEY}" `
		"${env:PROJECT_CHOCOLATEY_REPO_BRANCH}"
	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path
	if ($___process -ne 0) {
		$null = I18N-Commit-Failed
		return 1
	}


	# return status
	return 0
}




function RELEASE-Setup-CHOCOLATEY {
	# clean up base directory
	$null = I18N-Check "CHOCOLATEY"
	$___process = FS-Is-File "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
	if ($___process -eq 0) {
		$null = I18N-Check-Failed
		return 1
	}
	$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"


	# execute
	$null = I18N-Setup "CHOCOLATEY"
	$___process = GIT-Clone-Repo `
		"${env:PROJECT_PATH_ROOT}" `
		"${env:PROJECT_PATH_RELEASE}" `
		"$(Get-Location)" `
		"${env:PROJECT_CHOCOLATEY_REPO}" `
		"${env:PROJECT_SIMULATE_RELEASE_REPO}" `
		"${env:PROJECT_CHOCOLATEY_DIRECTORY}"
	if ($___process -ne 0) {
		$null = I18N-Setup-Failed
		return 1
	}


	# report status
	return 0
}
