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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\go.ps1"




# safety checking control surfaces
OS-Print-Status info "checking go availability..."
$__process = Go-Is-Available
if ($__process -ne 0) {
	OS-Print-Status error "missing go compiler."
	return 1
}


OS-Print-Status info "activating local environment..."
$__process = GO-Activate-Local-Environment
if ($__process -ne 0) {
	OS-Print-Status error "activation failed."
	return 1
}




# build output binary file
OS-Print-Status info "configuring build settings..."
$__output_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__arguments = ""
$__os = "${env:PROJECT_OS}"
$__arch = "${env:PROJECT_ARCH}"
switch ("${__os}/${__arch}") {
"aix/ppc64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "android/amd64" {
	return 1
} "android/arm64" {
	return 1
} "darwin/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
	$__arguments = "-buildmode=pie "
} "darwin/arm64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
	$__arguments = "-buildmode=pie "
} "dragonfly/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "freebsd/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "illumos/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "ios/amd64" {
	return 1
} "ios/arm64" {
	return 1
} "js/wasm" {
	$__filename = "${__output_directory}\${env:PROJECT_SKU}_${__os}-${__arch}.js"
	$null = FS-Remove-Silently "${__filename}"
	$__process = FS-Copy-File `
		"$(Invoke-Expression "go env GOROOT")/misc/wasm/wasm_exec.js" `
		"${__filename}"
	if ($__process -ne 0) {
		return 1
	}

	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}.wasm"
} "linux/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
	$__arguments = "-buildmode=pie "
} "linux/arm64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
	$__arguments = "-buildmode=pie "
} "linux/ppc64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "linux/ppc64le" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
	$__arguments = "-buildmode=pie "
} "linux/riscv64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "linux/s390x" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "netbsd/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "netbsd/arm64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "openbsd/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "openbsd/arm64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "plan9/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "solaris/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
} "wasip1/wasm" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}.wasi"
} "windows/amd64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}.exe"
	$__arguments = "-buildmode=pie "
} "windows/arm64" {
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}.exe"
	$__arguments = "-buildmode=pie "
} Default {
	return 1
}}




# building target
OS-Print-Status info "building ${__filename}..."
$__cgo = ${env:CGO_ENABLED}
$__go_os = ${env:GOOS}
$__go_arch = ${env:GOARCH}
${env:CGO_ENABLED} = 0
${env:GOOS} = $__os
${env:GOARCH} = $__arch
$__arguments = "build " `
	+ "-C `"${env:PROJECT_PATH_ROOT}/${env:PROJECT_GO}`" " `
	+ "${__arguments}" `
	+ "-ldflags `"-s -w`" " `
	+ "-trimpath " `
	+ "-gcflags `"-trimpath=${env:GOPATH}`" " `
	+ "-asmflags `"-trimpath=${GOPATH}`" "`
	+ "-o `"${__output_directory}\${__filename}`""

$null = FS-Remove-Silently "${__output_directory}\${__filename}"
$__process = OS-Exec "go" $__arguments
if ($__process -ne 0) {
	${env:CGO_ENABLED} = $__cgo
	${env:GOOS} = $__go_os
	${env:GOARCH} = $__go_arch
	OS-Print-Status error "build failed."
	return 1
}

${env:CGO_ENABLED} = $__cgo
${env:GOOS} = $__go_os
${env:GOARCH} = $__go_arch
$null = Remove-Variable -Name __cgo
$null = Remove-Variable -Name __go_os
$null = Remove-Variable -Name __go_arch




# exporting executable
$__source = "${__output_directory}\${__filename}"
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
