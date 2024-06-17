# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\deb.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




# define operating variables
$DEB_REPO_DATA = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\releaser-deb-repoDB"
if ($(STRINGS-Is-Empty "${env:PROJECT_DEB_PATH_DATA}") -ne 0) {
	$DEB_REPO_DATA = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\data\deb\${env:PROJECT_DEB_PATH_DATA}"
}

$DEB_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}" # default: flat mode
if ("$(${env:PROJECT_DEB_DISTRIBUTION} -replace "\/.*$", '')" -eq "${env:PROJECT_DEB_DISTRIBUTION}") {
	## conventional mode
	$DEB_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\deb"
	switch ("$(STRINGS-To-Lowercase "${env:PROJECT_RELEASE_REPO_TYPE}")") {
	"local" {
		# retain existing path
	} default {
		# fallback to git mode
		if ($(STRINGS-Is-Empty "${env:PROJECT_DEB_PATH}") -ne 0) {
			$DEB_REPO = "${DEB_REPO}\${PROJECT_DEB_PATH}"
		}
	}}

	## overrides if PROJECT_RELEASE_REPO is set
	if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -ne 0) {
		$DEB_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\deb"
	}
}




function RELEASE-Conclude-DEB {
	param(
		[string]$__repo_directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_DEB_URL}") -eq 0) {
		return 0 # disabled explictly
	}


	# execute
	$null = I18N-Conclude "DEB"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Conclude "DEB"
		return 0
	} elseif ("$($___distribution -replace "\/.*$", '')" -ne $___distribution) {
		# nothing to do in flat mode - report status
		return 0
	} elseif ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -ne 0) {
		# do nothing - single unified repository will take over later
		return 0
	}

	switch ("$(STRINGS-To-Lowercase "${env:PROJECT_RELEASE_REPO_TYPE}")") {
	"local" {
		# nothing to do for local directory type - report status
		return 0
	} default {
		# repository is an independent git repository so proceed as follows.
	}}


	# commit release
	$__current_path = Get-Location
	$null = Set-Location "${__repo_directory}"
	$___process = Git-Autonomous-Force-Commit `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_DEB_REPO_KEY}" `
		"${env:PROJECT_DEB_REPO_BRANCH}"
	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path
	if ($___process -ne 0) {
		$null = I18N-Conclude-Failed
		return 1
	}


	# return status
	return 0
}




function RELEASE-Run-DEB {
	param(
		[string]$__target,
		[string]$__repo_directory,
		[string]$__data_directory
	)


	# validate input
	$___process = DEB-Is-Valid "${__target}"
	if ($___process -ne 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_DEB_URL}") -eq 0) {
		return 0 # disabled explictly
	}


	# execute
	$null = I18N-Publish "DEB"
	if ($(OS-Is-Run-Simulated) -ne 0) {
		$___process = DEB-Publish `
			"${__repo_directory}" `
			"${__data_directory}" `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\releaser-deb" `
			"${__target}" `
			"${env:PROJECT_DEB_DISTRIBUTION}" `
			"${env:PROJECT_DEB_COMPONENT}"
		if ($___process -ne 0) {
			$null = I18N-Publish-Failed
			return 1
		}
	} else {
		# always simulate in case of error or mishaps before any point of no return
		$null = I18N-Simulate-Publish "DEB"
	}


	# report status
	return 0
}




function RELEASE-Setup-DEB {
	param(
		[string]$__repo_directory
	)


	# validate input
	$null = I18N-Check "DEB"
	if ($(STRINGS-Is-Empty "${env:PROJECT_DEB_URL}") -eq 0) {
		$null = I18N-Check-Disabled-Skipped
		return 0 # disabled explictly
	}


	# execute
	$null = I18N-Setup "DEB"
	if ("$($___distribution -replace "\/.*$", '')" -eq $___distribution) {
		# conventional mode
		if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -eq 0) {
			## overridden by single unified repository
			$null = FS-Remake-Directory "${__repo_directory}"
			return 0
		}

		switch ("$(STRINGS-To-Lowercase "${env:PROJECT_RELEASE_REPO_TYPE}")") {
		"local" {
			## local file directory type
			$null = FS-Remake-Directory "${__repo_directory}"
			return 0
		} default {
			## fallback to git repository source
		}}

		$null = FS-Make-Housing-Directory "${__repo_directory}"
		$___process = GIT-Clone-Repo `
			"${env:PROJECT_PATH_ROOT}" `
			"${env:PROJECT_PATH_RELEASE}" `
			"$(Get-Location)" `
			"${env:PROJECT_DEB_REPO}" `
			"${env:PROJECT_SIMULATE_RUN}" `
			"deb"
			if ($___process -ne 0) {
				$null = I18N-Setup-Failed
				return 1
			}

		$null = FS-Make-Directory "${__repo_directory}"
	}


	# report status
	return 0
}




function RELEASE-Update-DEB {
	param(
		[string]$__repo_directory,
		[string]$__data_directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_DEB_URL}") -eq 0) {
		return 0 # disabled explictly
	}


	# execute
	$null = I18N-Publish "DEB"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Publish "DEB"
		return 0
	}

	$___process = DEB-Publish-Conclude `
		"${__repo_directory}" `
		"${__data_directory}" `
		"${env:PROJECT_DEB_DISTRIBUTION}" `
		"${env:PROJECT_DEB_ARCH}" `
		"${env:PROJECT_DEB_COMPONENT}" `
		"${env:PROJECT_DEB_CODENAME}" `
		"${env:PROJECT_GPG_ID}"
	if ($___process -ne 0) {
		$null = I18N-Publish-Failed
		return 1
	}


	# create the README.md
	if ("$($___distribution -replace "\/.*$", '')" -ne $___distribution) {
		# it's flat repo so stop here - no README.md is required
		return 0
	}

	$___dest = "${__repo_directory}\DEB_Repository.md"
	$null = I18N-Create "${__dest}"
	$null = FS-Make-Housing-Directory "${__dest}"
	$null = FS-Remove-Silently "${__dest}"
	$___process = FS-Write-File "${__dest}" @"
# DEB Distribution Repository

This directory is now re-purposed to host DEB packages repository.

"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
