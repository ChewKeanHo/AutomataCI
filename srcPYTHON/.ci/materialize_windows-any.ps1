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


OS-Print-Status info "checking pyinstaller availability..."
$__process = OS-Is-Command-Available "pyinstaller"
if ($__process -ne 0) {
	OS-Print-Status error "missing pyinstaller command."
	return 1
}


OS-Print-Status info "checking pdoc availability..."
$__process = OS-Is-Command-Available "pdoc"
if ($__process -ne 0) {
	OS-Print-Status error "missing pdoc command."
	return 1
}




# build output binary file
switch (${env:PROJECT_OS}) {
windows {
	$__source = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}.exe"
} default {
	$__source = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
}}

OS-Print-Status info "building output file: ${__source}"
$__argument = "--noconfirm " `
	+ "--onefile " `
	+ "--clean " `
	+ "--distpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}`" " `
	+ "--workpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}`" " `
	+ "--specpath `"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}`" " `
	+ "--name `"${__source}`" " `
	+ "--hidden-import=main " `
	+ "`"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\main.py`""
$__process = OS-Exec "pyinstaller" "${__argument}"
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# exporting executable
$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__source}"
$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}\${env:PROJECT_SKU}.exe"
OS-Print-Status info "exporting ${__source} to ${__dest}"
$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}"
$null = FS-Remove-Silently "${__dest}"
$__process = FS-Move "${__source}" "${__dest}"
if ($__process -ne 0) {
	OS-Print-Status error "export failed."
	return 1
}




# report status
return 0
