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




# (0) initialize
IF (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
        Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
        exit 1
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

	# generate the setup.py
	$__process = FS-Write-File "${__directory}/setup.py" @"
from setuptools import setup, find_packages

setup(
    name='${env:PROJECT_NAME}',
    version='${env:PROJECT_VERSION}',
    author='${env:PROJECT_CONTACT_NAME}',
    author_email='${env:PROJECT_CONTACT_EMAIL}',
    url='${env:PROJECT_CONTACT_WEBSITE}',
    description='${env:PROJECT_PITCH}',
    packages=find_packages(),
    long_description=open('${env:PROJECT_PATH_ROOT}\README.md').read(),
    long_description_content_type='text/markdown',
)
"@
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}
