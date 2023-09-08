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




# (1) execute tech specific CI jobs if available
if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
	$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}"
	$__recipe = "${__recipe}\test_windows-any.ps1"
	OS-Print-Status info "Python technology detected. Parsing job recipe: ${__recipe}"

	$__process = FS-Is-File $__recipe
	if ($__process -ne 0) {
		OS-Print-Status error "Parse failed - missing file."
		exit 1
	}

	. $__recipe
	if (-not $?) {
		exit 1
	}
}




# (2) use default response since no localized CI jobs
exit 0
