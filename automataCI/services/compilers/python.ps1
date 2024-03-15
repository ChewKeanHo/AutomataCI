# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function PYTHON-Activate-VENV {
	# validate input
	$___process = PYTHON-Is-VENV-Activated
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___location = "$(PYTHON-Get-Activator-Path)"
	$___process = FS-Is-File "${___location}"
	if ($___process -ne 0) {
		return 1
	}

	. $___location
	$___process = PYTHON-Is-VENV-Activated
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function PYTHON-Check-PYPI-Login {
	# execute
	if (($(STRINGS-Is-Empty "${env:TWINE_USERNAME}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:TWINE_PASSWORD}") -eq 0)) {
		return 1
	}


	# report status
	return 0
}




function PYTHON-Clean-Artifact {
	param (
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___target}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = Get-ChildItem -Path "${___target}" -Recurse `
		| Where-Object {$_.Name -match "__pycache__|\.pyc$" } `
		| Remove-Item -Force -Recurse


	# report status
	return 0
}




function PYTHON-Create-PYPI-Archive {
	param (
		[string]$___directory,
		[string]$___destination
	)


	# valdiate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___destination}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory}\pyproject.toml"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___destination}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = PYTHON-PYPI-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# construct archive
	$___current_path = Get-Location
	Set-Location -Path $___directory

	$___process = OS-Exec "python" "-m build --sdist --wheel ${___directory}\."
	if ($___process -ne 0) {
		Set-Location -Path $___current_path
		Remove-Variable -Name ___current_path
		return 1
	}

	$___process = OS-Exec "twine" "check `"${___directory}\dist\*`""
	if ($___process -ne 0) {
		Set-Location -Path $___current_path
		Remove-Variable -Name ___current_path
		return 1
	}
	Set-Location -Path $___current_path
	Remove-Variable -Name ___current_path


	# export to destination
	foreach ($___file in (Get-ChildItem -Path "${___directory}\dist")) {
		$___process = FS-Move "${___file}" "${___destination}"
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function PYTHON-Create-PYPI-Config {
	param(
		[string]$___directory,
		[string]$___project_name,
		[string]$___version,
		[string]$___name,
		[string]$___email,
		[string]$___website,
		[string]$___pitch,
		[string]$___readme_path,
		[string]$___readme_type,
		[string]$___license
	)


	# validate input
	if (
		($(STRINGS-Is-Empty "${___directory}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___project_name}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___name}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___email}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___website}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___pitch}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___readme_path}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___readme_type}") -eq 0 ) -or
		($(STRINGS-Is-Empty "${___license}") -eq 0 )) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory}\${___readme_path}"
	if ($___process -ne 0) {
		return 1
	}


	# check existing overriding file
	$___process = FS-Is-File "${___directory}\pyproject.toml"
	if ($___process -eq 0) {
		return 2
	}


	# create default file
	$___process = FS-Write-File "${___directory}\pyproject.toml" @"
[build-system]
requires = [ 'setuptools' ]
build-backend = 'setuptools.build_meta'

[project]
name = '${___project_name}'
version = '${___version}'
description = '${___pitch}'

[project.license]
text = '${___license}'

[project.readme]
file = '${___readme_path}'
'content-type' = '${___readme_type}'

[[project.authors]]
name = '${___name}'
email = '${___email}'

[[project.maintainers]]
name = '${___name}'
email = '${___email}'

[project.urls]
Homepage = '${___website}'
"@
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function PYTHON-Get-Activator-Path {
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${env:PROJECT_PATH_PYTHON_ENGINE}\Scripts\Activate.ps1"
}




function PYTHON-Has-PIP {
	return OS-Is-Command-Available "pip"
}




function PYTHON-Is-Available {
	# execute
	$null = OS-Sync

	$___process = OS-Is-Command-Available "python3"
	if ($___process -eq 0) {
		return 0
	}

	$___process = OS-Is-Command-Available "python"
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function PYTHON-Is-Valid-PYPI {
	param(
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = STRINGS-Has-Prefix "pypi" (Split-Path -Leaf -Path "${___target}")
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___hasWHL = $false
	$___hasTAR = $false
	foreach ($___file in (Get-ChildItem -Path ${___target})) {
		if ($___file.Extension -eq ".whl") {
			$___hasWHL = $true
		} elseif ($___file.Extension -like ".tar.*") {
			$___hasTAR = $true
		}
	}
	if ($___hasWHL -and $___hasTAR) {
		return 0
	}


	# report status
	return 1
}




function PYTHON-Is-VENV-Activated {
	# execute
	if ($(STRINGS-Is-Empty "${env:VIRTUAL_ENV}") -ne 0) {
		return 0
	}


	# report status
	return 1
}




function PYTHON-PYPI-Is-Available {
	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_PYTHON}") -eq 0) {
		return 1
	}


	# execute
	if ($(PYTHON-Is-VENV-Activated) -ne 0) {
		return 1
	}

	if ($(OS-Is-Command-Available "twine") -ne 0) {
		return 1
	}


	# report status
	return 0
}




function PYTHON-Release-PYPI {
	param(
		[string]$___target,
		[string]$___gpg,
		[string]$___url
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___gpg}") -eq 0) -or
		($(STRINGS-Is-Empty "${___url}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = PYTHON-PYPI-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Exec "twine" "check ${___target}\*"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___arguments = "upload " `
			+ "--sign " `
			+ "--identity `"${___gpg}`" " `
			+ "--repository-url `"${___url}`" " `
			+ "--non-interactive"
	$___process = OS-Exec "twine" "${___arguments}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function PYTHON-Setup {
	# validate input
	$___process = OS-Is-Command-Available "choco"
	if ($___process -ne 0) {
		return 1
	}

	$___process =  OS-Is-Command-Available "python"
	if ($___process -eq 0) {
		return 0
	}

	$___process =  OS-Is-Command-Available "python3"
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___process = OS-Exec "choco" "install python -y"
	if ($___process -ne 0) {
		return 1
	}
	$null = OS-Sync

	$___process = PYTHON-Setup-VENV
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function PYTHON-Setup-VENV {
	# validate input
	if (($(STRINGS-Is-Empty "${env:PROJECT_PATH_ROOT}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_PATH_TOOLS}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_PATH_PYTHON_ENGINE}") -eq 0)) {
		return 1
	}

	$___process = PYTHON-Activate-VENV
	if ($___process -eq 0) {
		# already available
		return 0
	}


	# execute
	$___program = ""
	if ($(OS-Is-Command-Available "python3") -eq 0) {
		$___program = "python3"
	} elseif ($(OS-Is-Command-Available "python") -eq 0) {
		$___program = "python"
	} else {
		return 1
	}

	$___location = "${env:PROJECT_PATH_ROOT}" `
		+ "\${env:PROJECT_PATH_TOOLS}" `
		+ "\${env:PROJECT_PATH_PYTHON_ENGINE}"
	$___process = OS-Exec "${___program}" "-m venv `"${___location}`""
	if ($___process -ne 0) {
		return 1
	}

	$___process = PYTHON-Activate-VENV
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
