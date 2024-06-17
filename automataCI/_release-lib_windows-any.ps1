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
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Run-LIBS {
	param(
		[string]$__target
	)


	# validate input
	$___process = FS-Is-Target-A-Library "${__target}"
	if ($___process -ne 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_SOURCE_RELEASE_TAG_LATEST}") -eq 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_SOURCE_GIT_REMOTE}") -eq 0) {
		return 0
	}

	$___process = GIT-Is-Available
	if ($___process -ne 0) {
		return 0
	}


	# execute
	$__branch = "v${env:PROJECT_VERSION}"
	if ($(FS-Is-Target-A-NPM "${__target}") -eq 0) {
		if ($(STRINGS-Is-Empty "${env:PROJECT_NODE_BRANCH_TAG}") -eq 0) {
			return 0
		}

		$__branch = "${__branch}_${env:PROJECT_NODE_BRANCH_TAG}"
	} elseif ($(FS-Is-Target-A-C "${__target}") -eq 0) {
		if ($(STRINGS-Is-Empty "${env:PROJECT_C_BRANCH_TAG}") -eq 0) {
			return 0
		}

		$__branch = "${__branch}_${env:PROJECT_C_BRANCH_TAG}"
	} else {
		return 0
	}


	# begin publication
	$null = I18N-Publish "git@${__branch}"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Publish "${__branch}"
		return 0
	}


	# create workspace directory
	$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\release-branch_${__branch}"
	$___process = GIT-Setup-Workspace-Bare `
		"${env:PROJECT_SOURCE_GIT_REMOTE}" `
		"${__branch}" `
		"${__workspace}"
	if ($___process -ne 0) {
		$null = I18N-Publish-Failed
		return 1
	}


	# unpack package into directory
	if ($(FS-Is-Target-A-TARGZ "${__target}") -eq 0) {
		$___process = TAR-Extract-GZ "${__workspace}" "${__target}"
	} elseif ($(FS-Is-Target-A-TARXZ "${__target}") -eq 0) {
		$___process = TAR-Extract-XZ "${__workspace}" "${__target}"
	} elseif ($(FS-Is-Target-A-ZIP "${__target}") -eq 0) {
		$___process = ZIP-Extract "${__workspace}" "${__target}"
	} else {
		$___process = FS-Copy-File "${__target}" "${__workspace}"
	}

	if ($___process -ne 0) {
		$null = I18N-Publish-Failed
		return 1
	}


	# commit release
	$__current_path = Get-Location
	$null = Set-Location -Path "${__workspace}"
	$___process = GIT-Autonomous-Commit "${__branch}"
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path
	if ($___process -ne 0) {
		$null = I18N-Publish-Failed
		return 1
	}


	# push to upstream
	$___process = GIT-Push-Specific "${__workspace}" `
		"${env:PROJECT_SOURCE_GIT_REMOTE}" `
		"${__branch}"
		"${__branch}"
	if ($___process -ne 0) {
		$null = I18N-Publish-Failed
		return 1
	}

	$___process = GIT-Push-Specific "${__workspace}" `
		"${env:PROJECT_SOURCE_GIT_REMOTE}" `
		"${__branch}"
		"${env:PROJECT_SOURCE_RELEASE_TAG_LATEST}_$($__branch -replace "^.*_", '')"
	if ($___process -ne 0) {
		$null = I18N-Publish-Failed
		return 1
	}


	# report status
	return 0
}
