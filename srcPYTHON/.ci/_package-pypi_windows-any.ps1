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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\python.ps1"




function PACKAGE-Assemble-PYPI-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	$___process = FS-Is-Target-A-Source "${_target}"
	if ($___process -ne 0) {
		return 10
	}

	if ($(STRINGS-Is-Empty "$env:PROJECT_PYTHON") -eq 0) {
		return 10
	}


	# assemble the python package
	$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\Libs"
	$___dest = "${_directory}"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$null = PYTHON-Clean-Artifact "${___source}"
	$___process = FS-Copy-All "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___source = "${PROJECT_PATH_ROOT}/${PROJECT_PYPI_README}"
	$___dest = "${_directory}/${PROJECT_PYPI_README}"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$null = PYTHON-Clean-Artifact "${___source}"
	$___process = FS-Copy-File "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# generate the pyproject.toml
	$___dest = "${_directory}/pyproject.toml"
	$null = I18N-Create "${___dest}"
	$___process = FS-Write-File "${___dest}" @"
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
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
