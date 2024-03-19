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
. "${env:LIBS_AUTOMATACI}\services\compilers\c.ps1"




# execute
$null = FS-Remove-Silently "${env:PROJECT_PATH_ROOT}/${env:PROJECT_PATH_BIN}"
$null = FS-Remove-Silently "${env:PROJECT_PATH_ROOT}/${env:PROJECT_PATH_LIB}"

$__arguments = "$(C-Get-Strict-Settings)"
switch ("${env:PROJECT_OS}") {
"darwin" {
	$__arguments = "${__arguments} -fPIC"
} default {
	$__arguments = "${__arguments} -pie -fPIE"
}}

$__compiler = "$(C-Get-Compiler "${env:PROJECT_OS}" "${env:PROJECT_ARCH}")"
if ($(STRINGS-Is-Empty "${__compiler}") -eq 0) {
	$null = I18N-Build-Failed
	return 1
}




# build main executable
$null = I18N-Configure-Build-Settings
$__target = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
$__output = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\build-${__target}"
$__log = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\build-${__target}"
$__main = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}\executable.txt"
switch ("${env:PROJECT_OS}") {
"windows" {
	$__target = "${__workspace}\${__target}.exe"
} default {
	$__target = "${__workspace}\${__target}.elf"
}}

$null = I18N-Build "${__main}"
$null = FS-Make-Directory "${__output}"
$null = FS-Remove-Silently "${__target}"
$___process = C-Build "${__target}" `
		"${__main}" `
		"executable" `
		"${env:PROJECT_OS}" `
		"${env:PROJECT_ARCH}" `
		"${__workspace}" `
		"${__log}" `
		"${__compiler}" `
		"${__arguments}"
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




# build main library
$null = I18N-Configure-Build-Settings
$__target = "lib${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
$__output = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\build-${__target}"
$__log = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\build-${__target}"
$__main = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}\library.txt"
switch ("${env:PROJECT_OS}") {
"windows" {
	$__target = "${__workspace}\${__target}.dll"
} default {
	$__target = "${__workspace}\${__target}.a"
}}

$null = I18N-Build "${__main}"
$null = FS-Make-Directory "${__output}"
$null = FS-Remove-Silently "${__target}"
$___process = C-Build "${__target}" `
		"${__main}" `
		"library" `
		"${env:PROJECT_OS}" `
		"${env:PROJECT_ARCH}" `
		"${__workspace}" `
		"${__log}" `
		"${__compiler}" `
		"${__arguments}"
if ($___process -ne 0) {
	$null = I18N-Build-Failed
	return 1
}

$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LIB}\lib${env:PROJECT_SKU}"
if ("${env:PROJECT_OS}" -eq "windows") {
	$__dest = "${__dest}.dll"
} else {
	$__dest = "${__dest}.a"
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
