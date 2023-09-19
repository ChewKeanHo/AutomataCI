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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




function PACKAGE-Assemble-PYPI-Content {
	param (
		[string]$__target,
		[string]$__directory,
		[string]$__target_name,
		[string]$__target_os,
		[string]$__target_arch
	)

	# validate project
	$__process = FS-Is-Target-A-Source "$__target"
	if ($__process -ne 0) {
		return 10
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PYTHON)) {
		return 10
	}

	# assemble the python package
	PYTHON-Clean-Artifact "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}"
	$__process = FS-Copy-All "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\Libs" `
				"${__directory}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-File "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYPI_README}" `
				"${__directory}\${env:PROJECT_PYPI_README}"
	if ($__process -ne 0) {
		return 1
	}

	# generate the pyproject.toml
	$__process = FS-Write-File "${__directory}\pyproject.toml" @"
[build-system]
requires = [ 'setuptools' ]
build-backend = 'setuptools.build_meta'

[project]
name = '${env:PROJECT_NAME}'
version = '${env:PROJECT_VERSION}'
description = '${env:PROJECT_PITCH}'

[project.license]
text = '${env:PROJECT_LICENSE}'

[project.readme]
file = '${env:PROJECT_PYPI_README}'
'content-type' = '${env:PROJECT_PYPI_README_MIME}'

[[project.authors]]
name = '${env:PROJECT_CONTACT_NAME}'
email = '${env:PROJECT_CONTACT_EMAIL}'

[[project.maintainers]]
name = '${env:PROJECT_CONTACT_NAME}'
email = '${env:PROJECT_CONTACT_EMAIL}'

[project.urls]
Homepage = '${env:PROJECT_CONTACT_WEBSITE}'
"@
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}
