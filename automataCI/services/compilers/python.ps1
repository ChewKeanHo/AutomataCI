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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




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




function PYTHON-Clean-Artifact {
	$null = Get-ChildItem -Recurse `
		| Where-Object {$_.Name -match "__pycache__|\.pyc$" } `
		| Remove-Item -Force -Recurse
	return 0
}




function PYPI-Is-Available {
	if ([string]::IsNullOrEmpty($env:PROJECT_PYTHON)) {
		return 1
	}

	$__process = PYTHON-Is-VENV-Activated
	if ($__process -ne 0) {
		return 1
	}

	$__process = Get-Command twine -ErrorAction SilentlyContinue
	if (-not ($__process)) {
		return 1
	}

	return 0
}




function PYPI-Create-Setup-PY {
	param(
		[string]$__directory,
		[string]$__project_name,
		[string]$__version,
		[string]$__name,
		[string]$__email,
		[string]$__website,
		[string]$__pitch,
		[string]$__readme_path,
		[string]$__readme_type
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__project_name) -or
		[string]::IsNullOrEmpty($__version) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__website) -or
		[string]::IsNullOrEmpty($__pitch) -or
		[string]::IsNullOrEmpty($__readme_path) -or
		[string]::IsNullOrEmpty($__readtme_type) -or
		(-not (Test-Path -PathType Container -Path $__directory))) {
		Remove-Variable -Name __directory
		Remove-Variable -Name __project_name
		Remove-Variable -Name __version
		Remove-Variable -Name __name
		Remove-Variable -Name __email
		Remove-Variable -Name __website
		Remove-Variable -Name __pitch
		Remove-Variable -Name __readme_path
		Remove-Variable -Name __readme_type
		return 1
	}

	# check existing overriding file
	if (Test-Path -Path "${__directory}/setup.py") {
		return 2
	}

	# create default file
	$__process = FS-Write-File "${__directory}/setup.py" @"
from setuptools import setup, find_packages

setup(
    name='${__project_name}',
    version='${__version}',
    author='${__name}',
    author_email='${__email}',
    url='${__website}',
    description='${__pitch}',
    packages=find_packages(),
    long_description=open('${__readme_path}').read(),
    long_description_content_type='${__readme_type}',
)
"@

	# report status
	Remove-Variable -Name __directory
	Remove-Variable -Name __project_name
	Remove-Variable -Name __version
	Remove-Variable -Name __name
	Remove-Variable -Name __email
	Remove-Variable -Name __website
	Remove-Variable -Name __pitch
	Remove-Variable -Name __readme_path
	Remove-Variable -Name __readme_type
	return 0
}




function PYPI-Create-Archive {
	param (
		[string]$__directory,
		[string]$__destination
	)

	# valdiate input
	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__destination) -or
		(-not (Test-Path -PathType Container -Path $__directory))
		(-not (Test-Path -Path "${__directory}\setup.py")) -or
		(-not (Test-Path -PathType Container -Path $__destination))) {
		Remove-Variable -Name __directory
		Remove-Variable -Name __destination
		return 1
	}

	$__process = PYPI-Is-Available
	if ($__process -ne 0) {
		Remove-Variable -Name __directory
		Remove-Variable -Name __destination
		return 1
	}

	# construct archive
	$__current_path = Get-Location
	Set-Location -Path $__directory
	$__process = OS-Exec "python" "`"${__directory}\setup.py`" sdist bdist_wheel"
	if ($__process -ne 0) {
		Set-Location -Path $__current_path
		Remove-Variable -Name __current_path
		Remove-Variable -Name __directory
		Remove-Variable -Name __destination
		return 1
	}

	$__process = OS-Exec "twine" "check `"${__directory}\dist\*`""
	if ($__process -ne 0) {
		Set-Location -Path $__current_path
		Remove-Variable -Name __current_path
		Remove-Variable -Name __directory
		Remove-Variable -Name __destination
		return 1
	}
	Set-Location -Path $__current_path
	Remove-Variable -Name __current_path

	# export to destination
	$__process = FS-Move "${__directory}\dist\*" "${__destination}\."

	# report status
	Remove-Variable -Name __directory
	Remove-Variable -Name __destination
	return $__process
}
