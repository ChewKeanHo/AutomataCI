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
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




# define operating variables
$FLATPAK_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\flatpak"




function RELEASE-Conclude-FLATPAK {
	param(
		[string]$__repo_directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_FLATPAK_URL}") -eq 0) {
		return 0 # disabled explictly
	} elseif (($(STRINGS-Is-Empty "${env:PROJECT_FLATPAK_REPO}") -eq 0) -and
		($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -eq 0)) {
		return 0 # single file bundles only
	}

	switch ("$(STRINGS-To-Lowercase "${env:PROJECT_RELEASE_REPO_TYPE}")") {
	"local" {
		return 0 # do nothing
	} default {
		# it's a git repository
	}}


	# execute
	$null = I18N-Conclude "FLATPAK"
	$___process = FS-Is-Directory "${__repo_directory}"
	if ($___process -ne 0) {
		return 0 # no repository setup during package job
	}

	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Conclude "FLATPAK"
		return 0
	}


	# commit the git repository
	$__current_path = Get-Location
	$null = Set-Location "${__repo_directory}"
	$___process = GIT-Pull-To-Latest
	if ($___process -ne 0) {
		$null = Set-Location "${__curent_path}"
		$null = Remove-Variable __current_path
		$null = I18N-Conclude-Failed
		return 1
	}

	$___process = GIT-Autonomous-Commit "${env:PROJECT_SKU} ${env:PROJECT_VERSION}"
	if ($___process -ne 0) {
		$null = Set-Location "${__curent_path}"
		$null = Remove-Variable __current_path
		$null = I18N-Conclude-Failed
		return 1
	}

	$___process = GIT-Push `
		"${env:PROJECT_FLATPAK_REPO_KEY}" `
		"${env:PROJECT_FLATPAK_REPO_BRANCH}"
	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path
	if ($___process -ne 0) {
		$null = I18N-Conclude-Failed
		return 1
	}


	# return status
	return 0
}




function RELEASE-Setup-FLATPAK {
	param(
		[string]$__repo_directory
	)


	# validate input
	$null = I18N-Check "FLATPAK"
	if ($(STRINGS-Is-Empty "${env:PROJECT_FLATPAK_URL}") -eq 0) {
		$null = I18N-Check-Disabled-Skipped
		return 0 # disabled explictly
	}

	if (($(STRINGS-Is-Empty "${env:PROJECT_FLATPAK_REPO}") -eq 0) -and
		($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -eq 0)) {
		return 0 # single file bundles only
	}


	# execute
	$__source = "${PROJECT_PATH_ROOT}\${PROJECT_PATH_TEMP}\flatpak-repo"
	$___process = FS-Is-Directory "${__source}"
	if ($___process -ne 0) {
		return 0 # no repository setup during package job
	}

	$null = I18N-Setup "FLATPAK"
	$null = FS-Remove-Silently "${__repo_directory}"
	$___process = FS-Move "${__source}" "${__repo_directory}"
	if ($___process -ne 0) {
		$null = I18N-Setup-Failed
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -ne 0) {
		$null = FS-Remove-Silently "${__repo_directory}\.git"
	}


	# report status
	return 0
}
