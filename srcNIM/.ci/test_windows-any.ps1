# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\nim.ps1"




# execute
$null = I18N-Activate-Environment
$___process = NIM-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}"
$null = I18N-Prepare "${___source}"
$___arguments = "compileToC " `
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
	+ "--passC:-flto --passL:-flto " `
	+ "--mm:orc " `
	+ "--define:release " `
	+ "--opt:size " `
	+ "--colors:on " `
	+ "--styleCheck:off " `
	+ "--showAllMismatches:on " `
	+ "--tlsEmulation:on " `
	+ "--implicitStatic:on " `
	+ "--trmacros:on " `
	+ "--panics:on " `
	+ "--cc:gcc " `
	+ "--passC:-static --passL:-static " `
	+ "--cpu:${env:PROJECT_ARCH} "


# execute
$null = I18N-Run-Test
$___process = NIM-Run-Test `
	"${___source}" `
	"${env:PROJECT_OS}" `
	"${env:PROJECT_ARCH}" `
	"${___arguments}"
switch ("${___process}") {
{ $_ -in "0", "10" } {
	# accepted
} default {
	$null = I18N-Run-Failed
	return 1
}}




# report status
return 0
