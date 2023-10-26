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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\angular.ps1"




# execute
OS-Print-Status info "executing build..."
$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_ANGULAR}"
$__process = ANGULAR-Build
$null = Set-Location "${__current_path}"
$null = Remove-Variable __current_path
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# placeholding docs flag
$__file = "${env:PROJECT_SKU}-docs_any-any"
OS-Print-Status info "building output file: ${__file}"
$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__process = FS-Touch-File "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__file}"
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# report status
return 0
