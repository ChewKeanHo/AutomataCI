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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}





function RELEASE-Conclude-STATIC-REPO {
	# validate input
	$null = I18N-Source "GIT COMMIT ID"
	$__tag = GIT-Get-Latest-Commit-ID
	if ($(STRINGS-Is-Empty "${__tag}") -eq 0) {
		$null = I18N-Source-Failed
		return 1
	}


	# execute
	$__current_path = Get-Location
	$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\${env:PROJECT_STATIC_REPO_DIRECTORY}"

	$__file = "Home.md"
	$null = I18N-Create "${__file}"
	$null = FS-Write-File "${__file}" @"
# ${env:PROJECT_NAME} Static Distribution Repository

This is a re-purposed repository for housing various distribution ecosystem
such as but not limited to ``.deb``, ``.rpm``, ``.flatpak``, and etc for folks
to ``apt-get install``, ``yum install``, or ``flatpak install``.
"@

	$null = I18N-Commit "STATIC REPO"
	$___process = Git-Autonomous-Force-Commit `
		"${__tag}" `
		"${env:PROJECT_STATIC_REPO_KEY}" `
		"${env:PROJECT_STATIC_REPO_BRANCH}"

	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path


	# return status
	if ($___process -ne 0) {
		$null = I18N-Commit-Failed
		return 1
	}

	return 0
}




function RELEASE-Setup-STATIC-REPO {
	# clean up base directory
	$null = I18N-Check "STATIC REPO"
	if ($(FS-Is-File "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}") -eq 0) {
		$null = I18N-Check-Failed
		return 1
	}
	$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"


	# execute
	$null = I18N-Setup "STATIC REPO"
	$___process = GIT-Clone-Repo `
		"${env:PROJECT_PATH_ROOT}" `
		"${env:PROJECT_PATH_RELEASE}" `
		"$(Get-Location)" `
		"${env:PROJECT_STATIC_REPO}" `
		"${env:PROJECT_SIMULATE_RELEASE_REPO}" `
		"${env:PROJECT_STATIC_REPO_DIRECTORY}"
	if ($___process -ne 0) {
		$null = I18N-Setup-Failed
		return 1
	}

	$__staging = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${env:PROJECT_PATH_RELEASE}"
	$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\${env:PROJECT_STATIC_REPO_DIRECTORY}"
	if ($(FS-Is-Directory "${__staging}") -eq 0) {
		$null = I18N-Export "STATIC REPO"
		$___process = FS-Copy-All "${__staging}/" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Export-Failed
			return 1
		}
	}


	# report status
	return 0
}
