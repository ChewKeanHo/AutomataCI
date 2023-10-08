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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\compiler-c_windows-any.ps1"




# safety checking control surfaces
OS-Print-Status info "checking BUILD-Compile function availability..."
$__process = OS-Is-Command-Available "BUILD-Compile"
if ($__process -ne 0) {
	OS-Print-Status error "check failed."
	return 1
}

$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"

$SETTINGS_BIN = "-Wall" + " " `
	+ "-Wextra" + " " `
	+ "-std=gnu89" + " "`
	+ "-pedantic" + " "`
	+ "-Wstrict-prototypes" + " " `
	+ "-Wold-style-definition" + " "`
	+ "-Wundef" + " "`
	+ "-Wno-trigraphs" + " " `
	+ "-fno-strict-aliasing" + " "`
	+ "-fno-common" + " " `
	+ "-fshort-wchar" + " " `
	+ "-fstack-protector-all" + " " `
	+ "-Werror-implicit-function-declaration" + " "`
	+ "-Wno-format-security" + " " `
	+ "-pie -fPIE" + " "`
	+ "-Os" + " "`
	+ "-g0" + " "`
	+ "-static"

$COMPILER = ""




# execute
$__process = BUILD-Compile `
	"c_binary" `
	"windows" `
	"${env:PROJECT_ARCH}" `
	"automataCI.txt" `
	"$SETTINGS_BIN" `
	"$COMPILER"
if (($__process -ne 0) -and ($__process -ne 10)) {
	return 1
}


$__process = BUILD-Compile `
	"c_library" `
	"windows" `
	"${env:PROJECT_ARCH}" `
	"libs\sample\automataCI.txt" `
	"$SETTINGS_BIN" `
	"$COMPILER"
if (($__process -ne 0) -and ($__process -ne 10)) {
	return 1
}




# exporting executable
$__source = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}.exe"
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




# exporting library
$__source = "${env:PROJECT_SKU}-lib_${env:PROJECT_OS}-${env:PROJECT_ARCH}.dll"
$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__source}"
$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LIB}\lib${env:PROJECT_SKU}.dll"
OS-Print-Status info "exporting ${__source} to ${__dest}"
$null = FS-Make-Housing-Directory "${__dest}"
$null = FS-Remove-Silently "${__dest}"
$__process = FS-Move "${__source}" "${__dest}"
if ($__process -ne 0) {
	OS-Print-Status error "export failed."
	return 1
}




# report status
return 0