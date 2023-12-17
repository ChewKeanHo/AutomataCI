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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\rust.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




function RELEASE-Run-CARGO {
	param(
		[string]$_target
	)


	# validate input
	$___process = RUST-Crate-Is-Valid "${_target}"
	if ($___process -ne 0) {
		return 0
	}

	$null = I18N-Status-Print-Check-Availability "RUST"
	$___process = RUST-Activate-Local-Environment
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "RUST"
		return 1
	}


	# execute
	$null = I18N-Status-Print-Run-Publish "CARGO"
	if ($(STRINGS-Is-Empty "${env:PROJECT_SIMULATE_RELEASE_REPO}") -ne 0) {
		$null = I18N-Status-Print-Run-Publish-Simulated "CARGO"
	} else {
		$null = I18N-Status-Print-Run-Login-Check "CARGO"
		$___process = RUST-Cargo-Login
		if ($___process -ne 0) {
			$null = I18N-Status-Print-Run-Login-Check-Failed
			$null = I18N-Status-Print-Run-Logout
			$null = RUST-Cargo-Logout
			return 1
		}

		$___process = RUST-Cargo-Release-Crate "${_target}"

		$null = I18N-Status-Print-Run-Logout
		$____process = RUST-Cargo-Logout
		if ($____process -ne 0) {
			$null = I18N-Status-Print-Run-Logout-Failed
			return 1
		}

		if ($___process -ne 0) {
			$null = I18N-Status-Print-Run-Publish-Failed
			return 1
		}
	}

	$null = I18N-Status-Print-Run-Clean "${_target}"
	$null = FS-Remove-Silently "${_target}"


	# report status
	return 0
}
