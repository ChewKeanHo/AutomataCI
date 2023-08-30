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
        Write-Error "[ ERROR ] - Please source from ci.cmd instead!\n"
        exit 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\python.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\changelog.ps1"




# (1) safety checking control surfaces
OS-Print-Status info "checking changelog availability..."
$process = CHANGELOG-Is-Available
if ($process -ne 0) {
	OS-Print-Status error "changelog builder is unavailable."
	exit 1
}

OS-Print-Status info "checking python availability..."
$process = PYTHON-Is-Available
if ($process -ne 0) {
	OS-Print-Status error "missing python intepreter."
	exit 1
}

OS-Print-Status info "activating python venv..."
$process = PYTHON-Activate-VENV
if ($process -ne 0) {
	OS-Print-Status error "activation failed."
	exit 1
}




# (2) run build service
OS-Print-Status info "checking pyinstaller availability..."
$compiler = "pyinstaller"
$process = OS-Is-Command-Available $compiler
if ($process -ne 0) {
	OS-Print-Status error "missing $compiler command."
	exit 1
}


$file = $env:PROJECT_SKU + "_" + $env:PROJECT_OS + "-" + $env:PROJECT_ARCH
OS-Print-Status info "building output file: $file"
$argument = "--noconfirm " `
	+ "--onefile " `
	+ "--clean " `
	+ "--distpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}`" " `
	+ "--workpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}`" " `
	+ "--specpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}`" " `
	+ "--name `"${file}`" " `
	+ "--hidden-import=main " `
	+ "`"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\main.py`""
$process = OS-Exec $compiler $argument
if ($process -ne 0) {
	OS-Print-Status error "build failed."
	exit 1
}




# (3) build changelog entries
$file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog"
OS-Print-Status info "building ${env:PROJECT_VERSION} data changelog entry..."
$process = CHANGELOG-Build-Data-Entry $file
if ($process -ne 0) {
	OS-Print-Status error "build failed."
	exit 1
}


OS-Print-Status info "building ${env:PROJECT_VERSION} deb changelog entry..."
$process = CHANGELOG-Build-DEB-Entry `
	$file `
	$env:PROJECT_VERSION `
	$env:PROJECT_SKU `
	$env:PROJECT_DEBIAN_DISTRIBUTION `
	$env:PROJECT_DEBIAN_URGENCY `
	$env:PROJECT_CONTACT_NAME `
	$env:PROJECT_CONTACT_EMAIL `
	(Get-Date -Format 'R')
if ($process -ne 0) {
	OS-Print-Status error "build failed."
	exit 1
}




# (3) report successful status
OS-Print-Status success ""
exit 0
