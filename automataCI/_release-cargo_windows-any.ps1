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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\rust.ps1"




function RELEASE-Run-CARGO {
	param(
		[string]$_target
	)


	# validate input
	$__process = RUST-Crate-Is-Valid "${_target}"
	if ($__process -ne 0) {
		return 0
	}

	OS-Print-Status info "activating rust local environment..."
	$__process = RUST-Activate-Local-Environment
	if ($__process -ne 0) {
		OS-Print-Status error "activation failed."
		return 1
	}


	# execute
	OS-Print-Status info "releasing cargo package..."
	if (-not ([string]::IsNullOrEmpty(${env:PROJECT_SIMULATE_RELEASE_REPO}))) {
		OS-Print-Status warning "Simulating cargo package push..."
	} else {
		OS-Print-Status info "logging in cargo credentials..."
		$__process = RUST-Cargo-Login
		if ($__process -ne 0) {
			$null = RUST-Cargo-Logout
			OS-Print-Status error "check failed - (CARGO_PASSWORD)."
			return 1
		}

		$__process = RUST-Cargo-Release-Crate "${_target}"
		$null = RUST-Cargo-Logout
		if ($__process -ne 0) {
			OS-Print-Status error "release failed."
			return 1
		}
	}

	OS-Print-Status info "remove package artifact..."
	$null = FS-Remove-Silently "${_target}"


	# report status
	return 0
}
