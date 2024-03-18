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

. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\go.ps1"




# execute
$null = I18N-Activate-Environment
$___process = GO-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$null = I18N-Configure-Build-Settings
$__output_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__arguments = "$(GO-Get-Compiler-Optimization-Arguments `
			"${env:PROJECT_OS}" `
			"${env:PROJECT_ARCH}")"

$__filename = "$(GO-Get-Filename `
			"${env:PROJECT_SKU}" `
			"${env:PROJECT_OS}" `
			"${env:PROJECT_ARCH}")"
if ($(STRINGS-Is-Empty "${__filename}") -eq 0) {
	$null = I18N-Configure-Failed
	return 1
}


$null = I18N-Build "${__filename}"
$__cgo = ${env:CGO_ENABLED}
$__go_os = ${env:GOOS}
$__go_arch = ${env:GOARCH}
${env:CGO_ENABLED} = 0
${env:GOOS} = "${env:PROJECT_OS}"
${env:GOARCH} = "${env:PROJECT_ARCH}"
$__arguments = "build " `
	+ "-C `"${env:PROJECT_PATH_ROOT}/${env:PROJECT_GO}`" " `
	+ "${__arguments} " `
	+ "-ldflags `"-s -w`" " `
	+ "-trimpath " `
	+ "-gcflags `"-trimpath=${env:GOPATH}`" " `
	+ "-asmflags `"-trimpath=${GOPATH}`" "`
	+ "-o `"${__output_directory}\${__filename}`""
$null = FS-Remove-Silently "${__output_directory}\${__filename}"
$___process = OS-Exec "go" "${__arguments}"
${env:CGO_ENABLED} = $__cgo
${env:GOOS} = $__go_os
${env:GOARCH} = $__go_arch
$null = Remove-Variable -Name __cgo
$null = Remove-Variable -Name __go_os
$null = Remove-Variable -Name __go_arch
if ($___process -ne 0) {
	$null = I18N-Build-Failed
	return 1
}


$___source = "${__output_directory}\${__filename}"
$___dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BIN}\${env:PROJECT_SKU}"
if ("${env:PROJECT_OS}" -eq "windows") {
	$___dest = "${___dest}.exe"
}
$null = I18N-Export "${___source}" "${___dest}"
$null = FS-Make-Housing-Directory "${___dest}"
$null = FS-Remove-Silently "${___dest}"
$___process = FS-Move "${___source}" "${___dest}"
if ($___process -ne 0) {
	$null = I18N-Export-Failed
	return 1
}




# report status
return 0
