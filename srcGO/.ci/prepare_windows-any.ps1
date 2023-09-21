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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\go.ps1"




# safety checking control surfaces
OS-Print-Status info "checking go availability..."
$__process = GO-Is-Available
if ($__process -ne 0) {
	OS-Print-Status error "missing go compiler."
	return 1
}


OS-Print-Status info "activating local environment..."
$__process = GO-Activate-Local-Environment
if ($__process -ne 0) {
	OS-Print-Status error "activation failed."
	return 1
}




# execute
OS-Print-Status info "go get modules..."
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}/${env:PROJECT_GO}"
$__process = OS-Exec "go" "get ."
if ($__process -ne 0) {
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable -Name __current_path
	OS-Print-Status error "go get failed."
	return 1
}
$null = Set-Location "${__current_path}"
$null = Remove-Variable -Name __current_path




# return status
return 0
