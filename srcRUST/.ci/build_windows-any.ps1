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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\sync.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\c.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\rust.ps1"




# safety checking control surfaces
OS-Print-Status info "activating local environment..."
$__process = RUST-Activate-Local-Environment
if ($__process -ne 0) {
	OS-Print-Status error "activation failed."
	return 1
}




# parallel build executables
$__output_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$null = FS-Make-Directory "${__output_directory}"


$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\rust-build"
$null = FS-Make-Directory "${__log_directory}"


$__parallel_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\rust-parallel"
$null = FS-Make-Directory "${__parallel_directory}"




# configure build
$__build_targets = @(
	"windows|amd64|.exe"
	"windows|arm64|.exe"
	"wasip1|wasm|.wasm"
)

$__placeholders = @(
	"${env:PROJECT_SKU}-src_any-any"
	"${env:PROJECT_SKU}-homebrew_any-any"
	"${env:PROJECT_SKU}-chocolatey_any-any"
	"${env:PROJECT_SKU}-cargo_any-any"
	"${env:PROJECT_SKU}-msi_any-any"
)




## register targets and execute parallel build
function SUBROUTINE-Build {
	param(
		[string]$__line
	)

	# initialize
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\sync.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\c.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\rust.ps1"

	# generate input
	$__list = $__line -split "\|"
	$__log = $__list[6]
	$__linker = $__list[5]
	$__dest = $__list[4]
	$__source = $__list[3]
	$__workspace = $__list[2]
	$__filename = $__list[1]
	$__target = $__list[0]
	$__subject = Split-Path -Leaf -Path "${__dest}"

	if ($__linker -eq "none") {
		$__linker = ""
	}

	# prepare workspace
	$null = FS-Make-Housing-Directory "${__log}"

	# building target
	OS-Print-Status info "building ${__subject} in parallel..."
	$null = FS-Remake-Directory "${__workspace}"
	$__current_path = Get-Location
	$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}"

	$__arguments = "build " `
		+ "--release " `
		+ "--target-dir `"${__workspace}`" " `
		+ "--target `"${__target}`" "
	if (-not [string]::IsNullOrEmpty($__linker)) {
		$__arguments = $__arguments `
			+ "--config `"target.${__target}.linker='${__linker}'`" "
	}

	$__err_log = [IO.Path]::ChangeExtension("${__log}", '').TrimEnd('.') + "-error.txt"
	$__out_log = [IO.Path]::ChangeExtension("${__log}", '').TrimEnd('.') + "-output.txt"
	$__process = Start-Process -Wait `
		-Filepath "$(Get-Command "cargo" -ErrorAction SilentlyContinue)" `
		-RedirectStandardError "${__err_log}" `
		-RedirectStandardOutput "${__out_log}" `
		-NoNewWindow `
		-ArgumentList "${__arguments}" `
		-PassThru
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable __current_path
	if ($__process.ExitCode -ne 0) {
		OS-Print-Status error "build failed - ${__subject}"
		return 1
	}

	# export target
	$null = FS-Make-Housing-Directory "${__dest}"
	$null = FS-Remove-Silently "${__dest}"
	if (Test-Path -Path "${__source}.wasm") {
		$__process = FS-Move "${__source}.wasm" "${__dest}"
		if ($__process -ne 0) {
			OS-Print-Status error "build failed - ${__subject}"
			return 1
		}


		if (Test-Path -Path "${__source}.js") {
			$__dest = [System.IO.Path]::GetFileNameWithoutExtension($__dest) + ".js"
			$null = FS-Remove-Silently "${__dest}"
			$__process = FS-Move "${__source}.js" "${__dest}"
			if ($__process -ne 0) {
				OS-Print-Status error "build failed - ${__subject}"
				return 1
			}
		}
	} elseif (Test-Path -Path "${__source}.exe") {
		$__process = FS-Move "${__source}.exe" "${__dest}"
		if ($__process -ne 0) {
			OS-Print-Status error "build failed - ${__subject}"
			return 1
		}
	} else {
		$__process = FS-Move "${__source}" "${__dest}"
		if ($__process -ne 0) {
			OS-Print-Status error "build failed - ${__subject}"
			return 1
		}
	}

	# report status
	return 0
}


foreach ($__line in $__build_targets) {
	# parse target data
	$__list = $__line -split "\|"
	$__extension = $__list[2]
	$__arch = $__list[1]
	$__os = $__list[0]

	# generate input
	$__target = RUST-Get-Build-Target "${__os}" "${__arch}"
	$__filename = "${env:PROJECT_SKU}_${__os}-${__arch}"
	$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\rust-${__filename}"
	$__source = "${__workspace}\${__target}\release\${env:PROJECT_SKU}"
	$__dest = "${__output_directory}\${__filename}${__extension}"
	$__subject = "${__filename}${__extension}"
	$__log = "${__log_directory}\rust-${__filename}.txt"
	$__linker = C-Get-Compiler `
		"${__os}" `
		"${__arch}" `
		"${env:PROJECT_OS}" `
		"${env:PROJECT_ARCH}"

	# validate input
	OS-Print-Status info "registering ${__subject} build..."
	if ([string]::IsNullOrEmpty($__target)) {
		OS-Print-Status warning "register skipped - missing target."
		continue
	}

	## NOTE: perform any hard-coded host system restrictions or gatekeeping
	##       customization adjustments here.
	switch ($__arch) { ### adjust by CPU Architecture
	{ $_ -in "ppc64", "riscv64" } {
		OS-Print-Status warning "register skipped - ${__subject} unsupported."
		continue
	} wasm {
		$__linker = "none"
	} default {
		if ([string]::IsNullOrEmpty($__linker)) {
			OS-Print-Status warning "register skipped - missing linker."
			continue
		}
	}}

	switch ($__os) { ### adjust by OS
	darwin {
		if ("${env:PROJECT_OS}" -ne "darwin") {
			OS-Print-Status warning "register skipped - ${__subject} unsupported."
			continue
		}
	} windows {
		$__linker = "none"
	} fuchsia {
		$__linker = "none"
	} default {
	}}

	# execute
	OS-Print-Status info "adding rust cross-compiler (${__target})..."
	$__process = OS-Exec "rustup" "target add `"${__target}`""
	if ($__process -ne 0) {
		OS-Print-Status error "addition failed."
		return 1
	}

	$null = FS-Append-File "${__parallel_directory}\parallel.txt" @"
${__target}|${__filename}|${__workspace}|${__source}|${__dest}|${__linker}|${__log}
"@
}

OS-Print-Status info "begin parallel building..."
$__process = SYNC-Exec-Parallel `
	${function:SUBROUTINE-Build}.ToString() `
	"${__parallel_directory}\parallel.txt" `
	"${__parallel_directory}" `
	"$([System.Environment]::ProcessorCount)"
if ($__process -ne 0) {
	return 1
}




# placeholding flag files
foreach ($__file in $__placeholders) {
	OS-Print-Status info "building output file: ${__file}"
	$__process = FS-Touch-File `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__file}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
}




# compose documentations




# report status
return 0
