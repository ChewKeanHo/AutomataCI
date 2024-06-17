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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\homebrew.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




# define operating variables
$HOMEBREW_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\homebrew"




function RELEASE-Conclude-HOMEBREW {
	param(
		[string]$__repo_directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_HOMEBREW_URL}") -eq 0) {
		return 0 # disabled explictly
	}


	# execute
	$null = I18N-Conclude "HOMEBREW"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Conclude "HOMEBREW"
		return 0
	}


	# commit the formula first
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
		"${env:PROJECT_HOMEBREW_REPO_KEY}" `
		"${env:PROJECT_HOMEBREW_REPO_BRANCH}"
	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path
	if ($___process -ne 0) {
		$null = I18N-Conclude-Failed
		return 1
	}


	# clean up in case of other release configurations
	if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -ne 0) {
		# remove traces - single unified repository will take over later
		$___process = FS-Remove "${__repo_directory}"
		if ($___process -ne 0) {
			$null = I18N-Conclude-Failed
			return 1
		}
	}

	switch ("$(STRINGS-To-Lowercase "${env:PROJECT_RELEASE_REPO_TYPE}")") {
	"local" {
		# remove traces - formula is never stray from its tap repository.
	} default {
		return 0
	}}

	$___process = FS-Remove "${__repo_directory}"
	if ($___process -ne 0) {
		$null = I18N-Conclude-Failed
		return 1
	}


	# return status
	return 0
}




function RELEASE-Run-HOMEBREW {
	param(
		[string]$__target,
		[string]$__repo_directory
	)


	# validate input
	$___process = HOMEBREW-Is-Valid-Formula "${__target}"
	if ($___process -ne 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_HOMEBREW_URL}") -eq 0) {
		return 0 # disabled explictly
	}


	# execute
	$null = I18N-Publish "HOMEBREW"
	if ($(OS-Is-Run-Simulated) -ne 0) {
		$__dest = $(FS-Get-File "${__target}").Substring(0,1)
		$__dest = "${___repo_directory}\Formula\${__dest}\$(FS_Get_File "${__target}")"
		$null = FS-Make-Housing-Directory "${__dest}"
		$___process = FS-Copy-File "${__target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Publish-Failed
			return 1
		}
	} else {
		# always simulate in case of error or mishaps before any point of no return
		$null = I18N-Simulate-Publish "HOMEBREW"
	}


	# report status
	return 0
}




function RELEASE-Setup-HOMEBREW {
	param(
		[string]$__repo_directory
	)


	# validate input
	$null = I18N-Check "HOMEBREW"
	if ($(STRINGS-Is-Empty "${env:PROJECT_HOMEBREW_URL}") -eq 0) {
		$null = I18N-Check-Disabled-Skipped
		return 0 # disabled explictly
	}


	# execute
	$null = I18N-Setup "HOMEBREW"
	$null = FS-Make-Housing-Directory "${__repo_directory}"
	$___process = GIT-Clone-Repo `
		"${env:PROJECT_PATH_ROOT}" `
		"${env:PROJECT_PATH_RELEASE}" `
		"$(Get-Location)" `
		"${env:PROJECT_HOMEBREW_REPO}" `
		"${env:PROJECT_SIMULATE_RUN}" `
		"homebrew"
		if ($___process -ne 0) {
			$null = I18N-Setup-Failed
			return 1
		}

	$null = FS-Make-Directory "${__repo_directory}"


	# report status
	return 0
}
