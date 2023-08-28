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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"




function PYTHON-Is-Available {
	$__program = Get-Command python -ErrorAction SilentlyContinue
	if ($__program) {
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
	return OS-Exec "pip" "--version"
}




function PYTHON-Activate-VENV {
	if ($env:VIRTUAL_ENV) {
		return 0
	}

	$__location = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}" `
			+ "\${env:PROJECT_PATH_PYTHON_ENGINE}\Scripts" `
			+ "\Activate.ps1"

	if (-not (Test-Path "${__location}")) {
		return 1
	}

	. $__location
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

	$__process = PYTHON-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	# check if the repo is already established...
	$__location = "${env:PROJECT_PATH_ROOT}" `
			+ "\${env:PROJECT_PATH_TOOLS}" `
			+ "\${env:PROJECT_PATH_PYTHON_ENGINE}"
	if (Test-Path "${__location}\Scripts\Activate.ps1") {
		Remove-Variable -Name __location
		return 0
	}


	# it's a clean repo. Start setting up virtual environment...
	$__process = OS-Exec "python" "-m venv `"${__location}`""
	if ($__process -ne 0) {
		Remove-Variable -Name __location
		return 1
	}


	# last check
	if (Test-Path "${__location}\Scripts\Activate.ps1") {
		Remove-Variable -Name __process
		Remove-Variable -Name __location
		return 0
	}

	Remove-Variable -Name __process
	Remove-Variable -Name __location
	return 1
}
