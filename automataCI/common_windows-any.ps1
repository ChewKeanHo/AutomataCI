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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"




# validate input
OS-Print-Status info "Validating CI job..."
if ([string]::IsNullOrEmpty(${env:PROJECT_CI_JOB})) {
	OS-Print-Status info "Validation failed."
	return 1
}




# execute python if set
if (-not [string]::IsNullOrEmpty(${env:PROJECT_PYTHON})) {
	$__recipe = STRINGS-To-Lowercase "${env:PROJECT_CI_JOB}_windows-any.ps1"
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}\${__recipe}"
	$__process = FS-Is-File "${__recipe}"
	if ($__process -eq 0) {
		OS-Print-Status info "Python tech detected. Parsing job recipe: ${__recipe}"
		$__process = . $__recipe
		if ($__process -ne 0) {
			OS-Print-Status error "Parse failed."
			return 1
		}
	}
}




# execute baseline as last
$__recipe = STRINGS-To-Lowercase "${env:PROJECT_CI_JOB}_windows-any.ps1"
$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\${env:PROJECT_PATH_CI}\${__recipe}"
$__process = FS-Is-File "${__recipe}"
if ($__process -eq 0) {
	OS-Print-Status info "Baseline source detected. Parsing job recipe: ${__recipe}"
	$__process = . $__recipe
	if ($__process -ne 0) {
		OS-Print-Status error "Parse failed."
		return 1
	}
}




# report status
OS-Print-Status success "`n"
return 0
