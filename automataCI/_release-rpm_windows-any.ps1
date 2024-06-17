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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\rpm.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\createrepo.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




# define operating variables
$RPM_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}" # default: flat mode
if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_FLAT_MODE}") -eq 0) {
	## conventional mode
	$RPM_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\rpm"
	switch ("$(STRINGS-To-Lowercase "${env:PROJECT_RELEASE_REPO_TYPE}")") {
	"local" {
		# retain existing path
	} default {
		# fallback to git mode
		if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_PATH}") -ne 0) {
			$RPM_REPO = "${RPM_REPO}\${PROJECT_RPM_PATH}"
		}
	}}

	## overrides if PROJECT_RELEASE_REPO is set
	if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -ne 0) {
		$RPM_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\rpm"
	}
}




function RELEASE-Conclude-RPM {
	param(
		[string]$__repo_directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_URL}") -eq 0) {
		return 0 # disabled explictly
	}

	$___process = CREATEREPO-Is-Available
	if ($___process -ne 0) {
		return 0 # nothing to execute without createrepo or createrepo_c.
	}


	# execute
	$null = I18N-Conclude "RPM"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Conclude "RPM"
		return 0
	}


	if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_FLAT_MODE}") -ne 0) {
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
		"${env:PROJECT_RPM_REPO_KEY}" `
		"${env:PROJECT_RPM_REPO_BRANCH}"
	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path
	if ($___process -ne 0) {
		$null = I18N-Conclude-Failed
		return 1
	}


	# return status
	return 0
}




function RELEASE-Run-RPM {
	param(
		[string]$__target,
		[string]$__repo_directory
	)


	# validate input
	$___process = RPM-Is-Valid "${__target}"
	if ($___process -ne 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_URL}") -eq 0) {
		return 0 # disabled explictly
	}

	$___process = CREATEREPO-Is-Available
	if ($___process -ne 0) {
		return 0 # can't execute without createrepo or createrepo_c.
	}


	# execute
	$null = I18N-Publish "RPM"
	if ($(OS-Is-Run-Simulated) -ne 0) {
		if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_FLAT_MODE}") -eq 0) {
			$___process = FS-Copy-File `
				"${__target}" `
				"${__repo_directory}/$(FS-Get-File "${__target}")"
			if ($___process -ne 0) {
				$null = I18N-Publish-Failed
				return 1
			}
		}
	} else {
		# always simulate in case of error or mishaps before any point of no return
		$null = I18N-Simulate-Publish "RPM"
	}


	# report status
	return 0
}




function RELEASE-Setup-RPM {
	param(
		[string]$__repo_directory
	)


	# validate input
	$null = I18N-Check "RPM"
	if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_URL}") -eq 0) {
		$null = I18N-Check-Disabled-Skipped
		return 0 # disabled explictly
	}

	$null = I18N-Check-Availability "CREATEREPO"
	$___process = CREATEREPO-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Check-Failed-Skipped
		return 0 # pipeline cannot run without createrepo or createrepo_c
	}


	# execute
	$null = I18N-Setup "RPM"
	if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_FLAT_MODE}") -eq 0) {
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
			"${env:PROJECT_RPM_REPO}" `
			"${env:PROJECT_SIMULATE_RUN}" `
			"rpm"
			if ($___process -ne 0) {
				$null = I18N-Setup-Failed
				return 1
			}

		$null = FS-Make-Directory "${__repo_directory}"
	}


	# report status
	return 0
}




function RELEASE-Update-RPM {
	param(
		[string]$__repo_directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_URL}") -eq 0) {
		return 0 # disabled explictly
	}

	$___process = CREATEREPO-Is-Available
	if ($___process -ne 0) {
		return 0 # can't execute without createrepo or createrepo_c.
	}


	# execute
	$null = I18N-Publish "RPM"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Publish "RPM"
		return 0
	}

	$___process = CREATEREPO-Publish "${__repo_directory}"
	if ($___process -ne 0) {
		$null = I18N-Publish-Failed
		return 1
	}

	if ($(STRINGS-Is-Empty "$PROJECT_RPM_FLAT_MODE") -ne 0) {
		$___process = RPM-Flatten-Repo "${__repo_directory}" `
			"${env:PROJECT_RPM_REPOXML_NAME}" `
			"${env:PROJECT_RPM_METALINK}" `
			"${env:PROJECT_RPM_URL}"
		if ($___process -ne 0) {
			$null = I18N-Publish-Failed
			return 1
		}
	}


	# create the README.md
	if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_FLAT_MODE}") -eq 0) {
		# stop here - report status
		return 0
	}

	$___dest = "${__repo_directory}\RPM_Repository.md"
	$null = I18N-Create "${__dest}"
	$null = FS-Make-Housing-Directory "${__dest}"
	$null = FS-Remove-Silently "${__dest}"
	$___process = FS-Write-File "${__dest}" @"
# RPM Distribution Repository

This directory is now re-purposed to host RPM packages repository.

"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
