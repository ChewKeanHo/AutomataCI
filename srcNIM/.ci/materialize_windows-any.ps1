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


$null = I18N-Configure-Build-Settings
$__target = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__main = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}\${env:PROJECT_SKU}.nim"
$__arguments = "compileToC " `
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
	+ "--cpu:${env:PROJECT_ARCH} "

switch ("${env:PROJECT_OS}") {
"darwin" {
	$__arguments = "${__arguments} " `
		+ "--cc:clang " `
		+ "--passC:-fPIC"
} "windows" {
	$__arguments = "${__arguments} " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--os:${env:PROJECT_OS} "
} default {
	$__arguments = "${__arguments} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--os:${env:PROJECT_OS} "
}}

switch ("${env:PROJECT_OS}") {
"windows" {
	$__target = "${__workspace}\${__target}.exe"
} default {
	$__target = "${__workspace}\${__target}"
}}


$null = I18N-Build "${__main}"
$null = FS-Make-Directory "${__workspace}"
$null = FS-Remove-Silently "${__target}"
$___process = OS-Exec "nim" "${__arguments} --out:${__target} ${__main}"
if ($___process -ne 0) {
	$null = I18N-Build-Failed
	return 1
}


$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}\${env:PROJECT_SKU}"
if ("${env:PROJECT_OS}" -eq "windows") {
	$__dest = "${__dest}.exe"
}
$null = I18N-Export "${__target}" "${__dest}"
$null = FS-Make-Housing-Directory "${__dest}"
$null = FS-Remove-Silently "${__dest}"
$___process = FS-Move "${__target}" "${__dest}"
if ($___process -ne 0) {
	$null = I18N-Export-Failed
	return 1
}




# report status
return 0
