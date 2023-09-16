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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\python.ps1"




# safety checking control surfaces
OS-Print-Status info "checking python availability..."
$__process = PYTHON-Is-Available
if ($__process -ne 0) {
	OS-Print-Status error "missing python intepreter."
	return 1
}


OS-Print-Status info "activating python venv..."
$__process = PYTHON-Activate-VENV
if ($__process -ne 0) {
	OS-Print-Status error "activation failed."
	return 1
}


OS-Print-Status info "checking pip availability..."
$__process = PYTHON-Has-PIP
if ($__process -ne 0) {
	OS-Print-Status error "missing pip module manager."
	return 1
}




# run prepare service
OS-Print-Status info "upgrading pip to the latest..."
$__process = OS-Exec "python" "-m pip install --upgrade pip"
if ($__process -ne 0) {
	OS-Print-Status error "pip update failed."
	return 1
}


$__file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\requirements.txt"
OS-Print-Status info "executing pip install against ${__file}"
$__process = OS-Exec "pip" "install -r ${__file}"
if ($__process -ne 0) {
	OS-Print-Status error "pip install failed."
	return 1
}




# return status
OS-Print-Status success ""
return 0
