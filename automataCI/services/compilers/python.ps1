# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
function PYTHON-Is-Available {
	$program = Get-Command python -ErrorAction SilentlyContinue
	if ($program) {
		return 0
	}
	return 1
}

function PYTHON-Is-VENV-Activated {
	if ($env:VIRTUAL_ENV) {
		return 0
	}
	return 1
}

function PYTHON-Has-PIP {
	try {
		$null = pip --version
		return 0
	} catch {
		return 1
	}
}

function PYTHON-Activate-VENV {
	if ($env:VIRTUAL_ENV) {
		return 0
	}

	$location = $env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_TOOLS + "\" `
			+ $env:PROJECT_PATH_PYTHON_ENGINE + "\" `
			+ "Scripts\Activate.ps1"

	if (-not (Test-Path "$location")) {
		return 1
	}

	. $location
	if ($env:VIRTUAL_ENV) {
		return 0
	}

	return 1
}

function PYTHON-Setup-VENV {
	if (-not $env:PROJECT_PATH_ROOT) {
		return 1
	}

	if (-not $env:PROJECT_PATH_TOOLS) {
		return 1
	}

	if (-not $env:PROJECT_PATH_PYTHON_ENGINE) {
		return 1
	}

	$program = Get-Command python -ErrorAction SilentlyContinue
	if (-not ($program)) {
		return 1
	}

	$location = $env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_TOOLS + "\" `
			+ $env:PROJECT_PATH_PYTHON_ENGINE


	# check if the repo is already established...
	if (Test-Path "$location\Scripts\Activate.ps1") {
		return 0
	}


	# it's a clean repo. Start setting up virtual environment...
	$process = Start-Process -Wait `
				-FilePath "$program" `
				-NoNewWindow `
				-ArgumentList "-m venv `"$location`"" `
				-PassThru
	if ($process.ExitCode -ne 0) {
		return 1
	}


	# last check
	if (Test-Path "$location\Scripts\Activate.ps1") {
		return 0
	}


	return 1
}
