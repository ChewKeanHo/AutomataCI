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

$EXIT_CODE = 0




# compile for windows-amd64 (microprocessor)
$__process = BUILD-Compile `
	"c_binary" `
	"windows" `
	"amd64" `
	"automataCI.txt" `
	"$SETTINGS_BIN" `
	"$COMPILER"
if (($__process -ne 0) -and ($__process -ne 10)) {
	$EXIT_CODE = 1
}


$__process = BUILD-Compile `
	"c_library" `
	"windows" `
	"amd64" `
	"libs\sample\automataCI.txt" `
	"$SETTINGS_BIN" `
	"$COMPILER"
if (($__process -ne 0) -and ($__process -ne 10)) {
	$EXIT_CODE = 1
}




# compile for windows-arm64 (microprocessor)
$__process = BUILD-Compile `
	"c_binary" `
	"windows" `
	"arm64" `
	"automataCI.txt" `
	"$SETTINGS_BIN" `
	"$COMPILER"
if (($__process -ne 0) -and ($__process -ne 10)) {
	$EXIT_CODE = 1
}


$__process = BUILD-Compile `
	"c_library" `
	"windows" `
	"arm64" `
	"libs\sample\automataCI.txt" `
	"$SETTINGS_BIN" `
	"$COMPILER"
if (($__process -ne 0) -and ($__process -ne 10)) {
	$EXIT_CODE = 1
}




# report status
return $EXIT_CODE
