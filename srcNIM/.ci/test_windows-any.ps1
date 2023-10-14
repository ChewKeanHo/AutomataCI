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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\nim.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\operators_windows-any.ps1"




# safety checking control surfaces
OS-Print-Status info "checking nim availability..."
$__process = NIM-Is-Available
if ($__process -ne 0) {
	OS-Print-Status error "missing nim compiler."
	return 1
}


OS-Print-Status info "activating local environment..."
$__process = NIM-Activate-Local-Environment
if ($__process -ne 0) {
	OS-Print-Status error "activation failed."
	return 1
}


OS-Print-Status info "checking BUILD-Test function availability..."
$__process = OS-Is-Command-Available "Build-Test"
if ($__process -ne 0) {
	OS-Print-Status error "check failed."
	return 1
}


OS-Print-Status info "prepare nim workspace..."
$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}"
$__main = "${__source}\${env:PROJECT_SKU}.nim"

$SETTINGS_CC = "compileToC " `
	+ "--passC:-Wall --passL:-Wall " `
	+ "--passC:-Wextra --passL:-Wextra " `
	+ "--passC:-std=gnu89 --passL:-std=gnu89 " `
	+ "--passC:-pedantic --passL:-pedantic " `
	+ "--passC:-Wstrict-prototypes --passL:-Wstrict-prototypes " `
	+ "--passC:-Wold-style-definition --passL:-Wold-style-definition " `
	+ "--passC:-Wundef --passL:-Wundef " `
	+ "--passC:-Wno-trigraphs --passL:-Wno-trigraphs " `
	+ "--passC:-fno-strict-aliasing --passL:-fno-strict-aliasing " `
	+ "--passC:-fno-common --passL:-fno-common " `
	+ "--passC:-fshort-wchar --passL:-fshort-wchar " `
	+ "--passC:-fstack-protector-all --passL:-fstack-protector-all " `
	+ "--passC:-Werror-implicit-function-declaration --passL:-Werror-implicit-function-declaration " `
	+ "--passC:-Wno-format-security --passL:-Wno-format-security " `
	+ "--passC:-Os --passL:-Os " `
	+ "--passC:-g0 --passL:-g0 " `
	+ "--passC:-flto --passL:-flto"

$SETTINGS_NIM = "--mm:orc " `
	+ "--define:release " `
	+ "--opt:size " `
	+ "--colors:on " `
	+ "--styleCheck:off " `
	+ "--showAllMismatches:on " `
	+ "--tlsEmulation:on " `
	+ "--implicitStatic:on " `
	+ "--trmacros:on " `
	+ "--panics:on "

$__arguments = "${SETTINGS_CC} " `
	+ "${SETTINGS_NIM} " `
	+ "--cc:gcc " `
	+ "--passC:-static --passL:-static " `
	+ "--cpu:${env:PROJECT_ARCH} "




# checking nim package health
OS-Print-Status info "checking nim package health..."
$__process = NIM-Check-Package "${__source}"
if ($__process -ne 0) {
	OS-Print-Status error "check failed."
	return 1
}




# execute
$__process = BUILD-Test `
	"${env:PROJECT_NIM}" `
	"${env:PROJECT_OS}" `
	"${env:PROJECT_ARCH}" `
	"${__arguments}" `
	"nim"
if (($__process -ne 0) -and ($__process -ne 10)) {
	return 1
}




# report status
return 0
