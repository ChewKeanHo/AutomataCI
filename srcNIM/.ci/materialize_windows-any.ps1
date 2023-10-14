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


OS-Print-Status info "prepare nim workspace..."
$__target = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}"
$__main = "${__source}\${env:PROJECT_SKU}.nim"

$SETTINGS_CC = `
	"compileToC " `
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
	+ "--passC:-flto --passL:-flto "
$SETTINGS_NIM = `
	"--mm:orc " `
	+ "--define:release " `
	+ "--opt:size " `
	+ "--colors:on " `
	+ "--styleCheck:off " `
	+ "--showAllMismatches:on " `
	+ "--tlsEmulation:on " `
	+ "--implicitStatic:on " `
	+ "--trmacros:on " `
	+ "--panics:on "




# execute
$null = FS-Make-Directory "${__workspace}"


OS-Print-Status info "checking nim package health..."
$__process = NIM-Check-Package "${__source}"
if ($__process -ne 0) {
	OS-Print-Status error "check failed."
	return 1
}


OS-Print-Status info "building nim application..."
$__arguments = "${SETTINGS_CC} " `
	+ "${SETTINGS_NIM} " `
	+ "--passC:-static --passL:-static " `
	+ "--passC:-s --passL:-s " `
	+ "--os:${env:PROJECT_OS} " `
	+ "--cpu:${env:PROJECT_ARCH} " `
	+ "--out:${__workspace}\${__target} "
$__process = OS-Exec "nim" "${__arguments} ${__main}"
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# exporting executable
$__source = "${__workspace}\${__target}.exe"
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
