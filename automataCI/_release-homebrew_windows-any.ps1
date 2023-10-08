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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\installer.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\versioners\git.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\homebrew.ps1"




function RELEASE-Run-Homebrew {
	param(
		[string]$__target,
		[string]$__repo
	)


	# validate input
	OS-Print-Status info "registering ${__target} into homebrew repo..."
	if ([string]::IsNullOrEmpty($__target) -or [string]::IsNullOrEmpty($__repo)) {
		OS-Print-Status error "registration failed."
		return 1
	}


	$__process = HOMEBREW-Is-Valid-Formula "${__target}"
	if ($__process -ne 0) {
		return 0
	}


	# execute
	$__process = HOMEBREW-Publish "${__target}" "${__repo}/Formula/${env:PROJECT_SKU}.rb"
	if ($__process -ne 0) {
		OS-Print-Status error "registration failed."
		return 1
	}


	# report status
	return 0
}




function RELEASE-Run-Homebrew-Repo-Conclude {
	param(
		[string]$__directory
	)


	# validate input
	OS-Print-Status info "Committing homebrew release repo..."
	if ([string]::IsNullOrEmpty($__directory) -or
		(-not (Test-Path -PathType Container -Path "${__directory}"))) {
		OS-Print-Status error "commit failed."
		return 1
	}


	# execute
	$__current_path = Get-Location
	$null = Set-Location "${__directory}"
	$__process = GIT-Autonomous-Commit `
		"${env:PROJECT_SKU} ${env:PROJECT_VERSION}" `
		"${env:PROJECT_HOMEBREW_REPO_KEY}" `
		"${env:PROJECT_HOMEBREW_REPO_BRANCH}"
	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path
	if ($__process -ne 0) {
		OS-Print-Status error "commit failed."
		return 1
	}


	# return status
	return 0
}




function RELEASE-Run-Homebrew-Repo-Setup {
	# clean up base directory
	OS-Print-Status info "safety checking release directory..."
	if (Test-Path -PathType Leaf `
		-Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}") {
		OS-Print-Status error "check failed."
		return 1
	}
	$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"


	# execute
	OS-Print-Status info "Setting up homebrew release repo..."
	$__process = INSTALLER-Setup-Homebrew-Repo `
		"${env:PROJECT_PATH_ROOT}" `
		"${env:PROJECT_PATH_RELEASE}" `
		"$(Get-Location)" `
		"${env:PROJECT_HOMEBREW_REPO}" `
		"${env:PROJECT_SIMULATE_RELEASE_REPO}" `
		"${env:PROJECT_HOMEBREW_DIRECTORY}"
	if ($__process -ne 0) {
		OS-Print-Status error "setup failed."
		return 1
	}


	# report status
	return 0
}