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
. "${env:LIBS_AUTOMATACI}\services\compilers\go.ps1"




# execute
$null = I18N-Activate-Environment
$___process = GO-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$__placeholders = @(
	"${env:PROJECT_SKU}-src_any-any"
	"${env:PROJECT_SKU}-homebrew_any-any"
	"${env:PROJECT_SKU}-chocolatey_any-any"
	"${env:PROJECT_SKU}-msi_any-any"
)


$__output_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__work_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}"
$__cgo = ${env:CGO_ENABLED}
$__go_os = ${env:GOOS}
$__go_arch = ${env:GOARCH}
${env:CGO_ENABLED} = 0
:loop foreach ($__platform in (Invoke-Expression "go tool dist list")) {
	# select supported platforms
	$__os = $__platform.Split("/")[0]
	$__arch = $__platform.Split("/")[1]
	switch ("${__os}-${__arch}") {
	"android-amd64" {
		continue loop #impossible without cgo
	} "android-386" {
		continue loop #impossible without cgo
	} "android-arm" {
		continue loop #impossible without cgo
	} "android-arm64" {
		continue loop #impossible without cgo
	} "ios-amd64" {
		continue loop
	} "ios-arm64" {
		continue loop
	} "js-wasm" {
		$__filename = "${__output_directory}\${env:PROJECT_SKU}_${__os}-${__arch}.js"
		$null = FS-Remove-Silently "${__filename}"
		$___process = FS-Copy-File `
			"$(Invoke-Expression "go env GOROOT")/misc/wasm/wasm_exec.js" `
			"${__filename}"
		if ($___process -ne 0) {
			return 1
		}
	} Default {
		# proceed
	}}
	$__arguments = "$(GO-Get-Compiler-Optimization-Arguments "${__os}" "${__arch}")"
	$__filename = "$(GO-Get-Filename "${env:PROJECT_SKU}" "${__os}" "${__arch}")"

	$null = I18N-Build "${__filename}"
	$null = FS-Remove-Silently "${__output_directory}\${__filename}"
	${env:GOOS} = $__os
	${env:GOARCH} = $__arch
	$__arguments = "build " `
		+ "-C `"${env:PROJECT_PATH_ROOT}/${env:PROJECT_GO}`" " `
		+ "${__arguments} " `
		+ "-ldflags `"-s -w`" " `
		+ "-trimpath " `
		+ "-gcflags `"-trimpath=${env:GOPATH}`" " `
		+ "-asmflags `"-trimpath=${GOPATH}`" "`
		+ "-o `"${__output_directory}\${__filename}`""
	$___process = OS-Exec "go" "${__arguments}"
	if ($___process -ne 0) {
		${env:CGO_ENABLED} = $__cgo
		${env:GOOS} = $__go_os
		${env:GOARCH} = $__go_arch
		$null = I18N-Build-Failed
		return 1
	}
}
${env:CGO_ENABLED} = $__cgo
${env:GOOS} = $__go_os
${env:GOARCH} = $__go_arch
$null = Remove-Variable -Name __cgo
$null = Remove-Variable -Name __go_os
$null = Remove-Variable -Name __go_arch




# placeholding flag files
foreach ($__line in $__placeholders) {
	$__file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__line}"
	$null = I18N-Build "${__file}"
	$___process = FS-Touch-File "${__file}"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed
		return 1
	}
}




# report status
return 0
