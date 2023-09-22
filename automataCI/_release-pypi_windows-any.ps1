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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\python.ps1"




function RELEASE-Run-PYPI {
	param(
		[string]$_target,
		[string]$_directory,
		[string]$_datastore
	)

	# validate input
	$__process = PYPI-Is-Valid "${_target}"
	if ($__process -ne 0) {
		return 0
	}

	OS-Print-Status info "activating python venv..."
	$__process = PYPI-Activate-VENV
	if ($__process -ne 0) {
		OS-Print-Status error "activation failed."
		return 1
	}

	OS-Print-Status info "checking python availability..."
	$__process = PYPI-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "check failed."
		return 1
	}

	OS-Print-Status info "checking pypi twine login credentials..."
	$__process = PYPI-Check-Login
	if ($__process -ne 0) {
		OS-Print-Status error "check failed - (TWINE_USERNAME|TWINE_PASSWORD)."
		return 1
	}

	# execute
	OS-Print-Status info "releasing pypi package..."
	if (-not ([string]::IsNullOrEmpty(${env:PROJECT_SIMULATE_RELEASE_REPO}))) {
		OS-Print-Status warning "Simulating pypi package push..."
		OS-Print-Status warning "Simulating remove package artifact..."
	} else {
		$__process = PYPI-Release `
			"${_target}" `
			"${env:PROJECT_GPG_ID}" `
			"${env:PROJECT_PYPI_REPO_URL}"
		if ($__process -ne 0) {
			OS-Print-Status error "release failed."
			return 1
		}

		OS-Print-Status info "processing package artifact for local distribution..."
		$null = FS-Remove-Silently "${_target}"
	}

	# report status
	return 0
}
