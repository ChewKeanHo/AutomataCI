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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\python.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




function RELEASE-Run-PYPI {
	param(
		[string]$_target
	)


	# validate input
	$___process = PYTHON-Is-Valid-PYPI "${_target}"
	if ($___process -ne 0) {
		return 0
	}

	$null = I18N-Status-Print-Check-Availability "PYTHON"
	$___process = PYTHON-Activate-VENV
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "PYTHON"
		return 1
	}

	$null = I18N-Status-Print-Check-Availability "PYPI"
	$___process = PYTHON-PYPI-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "PYPI"
		return 1
	}


	# execute
	$null = I18N-Status-Print-Run-Publish "PYPI"
	if ($(STRINGS-Is-Empty "${env:PROJECT_SIMULATE_RELEASE_REPO}") -ne 0) {
		$null = I18N-Status-Print-Run-Publish-Simulated "PYPI"
	} else {
		$null = I18N-Status-Print-Run-Login-Check "PYPI"
		$___process = PYHTON-Check-PYPI-Login
		if ($___process -ne 0) {
			$null = I18N-Status-Print-Run-Login-Check-Failed
			return 1
		}

		$___process = PYTHON-Release-PYPI `
			"${_target}" `
			"${env:PROJECT_GPG_ID}" `
			"${env:PROJECT_PYPI_REPO_URL}"
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
