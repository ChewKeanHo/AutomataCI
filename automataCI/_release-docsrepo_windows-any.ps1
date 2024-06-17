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
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Conclude-DOCS {
	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_DOCS_URL}") -eq 0) {
		return 0 # disabled explicitly
	}


	# execute
	$null = I18N-Publish "DOCS"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Conclude "DOCS"
		return 0
	}

	$___process = FS-Is-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_DOCS}"
	if ($___process -ne 0) {
		return 0
	}

	$___process = FS-Is-File "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
	if ($___process -eq 0) {
		$null = I18N-Publish-Failed
		return 1
	}

	$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"

	$null = I18N-Setup "DOCS"
	$__directory_name = "x_docsrepo"
	$___process = GIT-Clone-Repo `
		"${env:PROJECT_PATH_ROOT}" `
		"${env:PROJECT_PATH_RELEASE}" `
		"$(Get-Location)" `
		"${env:PROJECT_DOCS_REPO}" `
		"${env:PROJECT_SIMULATE_RUN}" `
		"${__directory_name}" `
		"${env:PROJECT_DOCS_REPO_BRANCH}"
	if ($___process -ne 0) {
		$null = I18N-Setup-Failed
		return 1
	}


	# export contents
	$__staging = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_DOCS}"
	$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\${__directory_name}"

	$null = I18N-Export "${__staging}"
	$___process = FS-Copy-All "${__staging}\" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Export-Failed
		$null = FS-Remove-Silently "${__dest}"
		return 1
	}

	$__tag = GIT-Get-Latest-Commit-ID
	$null = I18N-Commit "${__tag}"
	if ($(STRINGS-Is-Empty "${__tag}") -eq 0) {
		$null = I18N-Commit-Failed
		$null = FS-Remove-Silently "${__dest}"
		return 1
	}

	$___current_path = Get-Location
	$null = Set-Location "${__dest}"

	$___process = Git-Autonomous-Force-Commit `
		"${__tag}" `
		"${env:PROJECT_DOCS_REPO_KEY}" `
		"${env:PROJECT_DOCS_REPO_BRANCH}"

	$null = Set-Location "${___current_path}"
	$null = Remove-Variable ___current_path

	if ($___process -ne 0) {
		$null = I18N-Commit-Failed
		$null = FS-Remove-Silently "${__dest}"
		return 1
	}

	$null = FS-Remove-Silently "${__dest}"


	# return status
	return 0
}
