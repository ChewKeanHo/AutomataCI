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
. "${env:LIBS_AUTOMATACI}\services\compilers\rust.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




function RELEASE-Run-CARGO {
	param(
		[string]$_target
	)


	# validate input
	$___process = RUST-Crate-Is-Valid "${_target}"
	if ($___process -ne 0) {
		return 0
	}

	$null = I18N-Check-Availability "RUST"
	$___process = RUST-Activate-Local-Environment
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		return 1
	}


	# execute
	$null = I18N-Publish "CARGO"
	if ($(OS-Is-Run-Simulated) -eq 0) {
		$null = I18N-Simulate-Publish "CARGO"
	} else {
		$null = I18N-Check-Login "CARGO"
		$___process = RUST-Cargo-Login
		if ($___process -ne 0) {
			$null = I18N-Check-Failed
			$null = I18N-Logout "CARGO"
			$null = RUST-Cargo-Logout
			return 1
		}

		$___process = RUST-Cargo-Release-Crate "${_target}"
		if ($___process -ne 0) {
			$null = I18N-Logout "CARGO"
			$null = RUST-Cargo-Logout
			$null = I18N-Publish-Failed
			return 1
		}

		$null = I18N-Logout "CARGO"
		$___process = RUST-Cargo-Logout "CARGO"
		if ($___process -ne 0) {
			$null = I18N-Logout-Failed
			return 1
		}
	}

	$null = I18N-Clean "${_target}"
	$null = FS-Remove-Silently "${_target}"


	# report status
	return 0
}
