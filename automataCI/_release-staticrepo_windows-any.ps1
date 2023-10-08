# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\versioners\git.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\installer.ps1"




function RELEASE-Run-Release-Repo-Conclude {
	# validate input
	OS-Print-Status info "Sourcing commit id for tagging..."
	$__tag = GIT-Get-Latest-Commit-ID
	if ([string]::IsNullOrEmpty(${__tag})) {
		OS-Print-Status error "Source failed."
		return 1
	}


	# execute
	$__current_path = Get-Location
	$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\${env:PROJECT_STATIC_REPO_DIRECTORY}"

	OS-Print-Status info "Generate required notice file..."
	$null = FS-Write-File "Home.md" @"
# ${env:PROJECT_NAME} Static Distribution Repository

This is a re-purposed repository for housing various distribution ecosystem
such as but not limited to ``.deb``, ``.rpm``, ``.flatpak``, and etc for folks
to ``apt-get install``, ``yum install``, or ``flatpak install``.
"@

	OS-Print-Status info "Committing release repo..."
	$__process = Git-Autonomous-Force-Commit `
		"${__tag}" `
		"${env:PROJECT_STATIC_REPO_KEY}" `
		"${env:PROJECT_STATIC_REPO_BRANCH}"

	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path


	# return status
	if ($__process -ne 0) {
		OS-Print-Status error "Commit failed."
		return 1
	}

	return 0
}




function RELEASE-Run-Static-Repo-Setup {
	# clean up base directory
	OS-Print-Status info "safety checking static repo release directory..."
	if (Test-Path -PathType Leaf `
		-Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}") {
		OS-Print-Status error "check failed."
		return 1
	}
	$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"


	# execute
	OS-Print-Status info "setting up release static repo..."
	$__process = INSTALLER-Setup-Release-Repo `
		"${env:PROJECT_PATH_ROOT}" `
		"${env:PROJECT_PATH_RELEASE}" `
		"$(Get-Location)" `
		"${env:PROJECT_STATIC_REPO}" `
		"${env:PROJECT_SIMULATE_RELEASE_REPO}" `
		"${env:PROJECT_STATIC_REPO_DIRECTORY}"
	if ($__process -ne 0) {
		OS-Print-Status error "setup failed."
		return 1
	}


	# execute
	$__staging = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${env:PROJECT_PATH_RELEASE}"
	$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\${env:PROJECT_STATIC_REPO_DIRECTORY}"
	if (Test-Path -PathType Container -Path "${__staging}") {
		OS-Print-Status info "exporting staging contents to static repo..."
		$__process = FS-Copy-All "${__staging}/" "$__dest"
		if ($__process -ne 0) {
			OS-Print-Status error "export failed."
			return 1
		}
	}


	# report status
	return 0
}