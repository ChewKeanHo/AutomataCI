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

. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\sync.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\c.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\rust.ps1"




# execute
$null = I18N-Activate-Environment
$___process = RUST-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}




# parallel build executables
$__output_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$null = FS-Make-Directory "${__output_directory}"


$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\rust-build"
$null = FS-Make-Directory "${__log_directory}"


$__parallel_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\rust-parallel"
$null = FS-Make-Directory "${__parallel_directory}"


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


function SUBROUTINE-Build {
	param(
		[string]$__line
	)


	# initialize
	. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
	. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
	. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
	. "${env:LIBS_AUTOMATACI}\services\io\sync.ps1"
	. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
	. "${env:LIBS_AUTOMATACI}\services\compilers\c.ps1"
	. "${env:LIBS_AUTOMATACI}\services\compilers\rust.ps1"


	# generate input
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		return 0
	}
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
	$null = I18N-Build-Parallel "${__subject}"
	$null = FS-Remake-Directory "${__workspace}"
	$__current_path = Get-Location
	$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}"

	$__arguments = "build " `
		+ "--release " `
		+ "--target-dir `"${__workspace}`" " `
		+ "--target `"${__target}`" "
	if ($(STRINGS-Is-Empty "${__linker}") -ne 0) {
		$__arguments = $__arguments `
			+ "--config `"target.${__target}.linker='${__linker}'`" "
	}

	$__err_log = "$(FS-Extension-Remove "${__log}" "*")-error.txt"
	$__out_log = "$(FS-Extension-Remove "${__log}" "*")-output.txt"
	$___process = Start-Process -Wait `
		-Filepath "$(Get-Command "cargo" -ErrorAction SilentlyContinue)" `
		-RedirectStandardError "${__err_log}" `
		-RedirectStandardOutput "${__out_log}" `
		-NoNewWindow `
		-ArgumentList "${__arguments}" `
		-PassThru
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable __current_path
	if ($___process.ExitCode -ne 0) {
		$null = I18N-Build-Failed-Parallel "${__subject}"
		return 1
	}


	# export target
	$null = FS-Make-Housing-Directory "${__dest}"
	if ($(FS-Is-File "${__source}.wasm") -eq 0) {
		$__dest = "$(FS-Extension-Remove "${__dest}" ".wasm").wasm"
		$null = FS-Remove-Silently "${__dest}"
		$___process = FS-Move "${__source}.wasm" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed-Parallel "${__subject}"
			return 1
		}

		if ($(FS-Is-File "${__source}.js") -eq 0) {
			$__dest = "$(FS-Extension-Remove "${__dest}" ".js").js"
			$null = FS-Remove-Silently "${__dest}"
			$___process = FS-Move "${__source}.js" "${__dest}"
			if ($___process -ne 0) {
				$null = I18N-Build-Failed-Parallel "${__subject}"
				return 1
			}
		}
	} elseif ($(FS-Is-File "${__source}.exe") -eq 0) {
		$__dest = "$(FS-Extension-Remove "${__dest}" ".exe").exe"
		$null = FS-Remove-Silently "${__dest}"
		$___process = FS-Move "${__source}.exe" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed-Parallel "${__subject}"
			return 1
		}
	} else {
		$___process = FS-Move "${__source}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed-Parallel "${__subject}"
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
	$__linker = "$(C-Get-Compiler `
		"${__os}" `
		"${__arch}" `
		"${env:PROJECT_OS}" `
		"${env:PROJECT_ARCH}" `
	)"


	# validate input
	$null = I18N-Sync-Register "${__subject}"
	if ($(STRINGS-Is-Empty "${__target}") -eq 0) {
		$null = I18N-Sync-Register-Skipped-Missing-Target
		continue
	}

	## NOTE: perform any hard-coded host system restrictions or gatekeeping
	##       customization adjustments here.
	switch ($__arch) { ### filter by CPU Architecture
	{ $_ -in "ppc64", "riscv64" } {
		$null = I18N-Sync-Register-Skipped-Unsupported
		continue
	} wasm {
		$__linker = "none"
	} default {
		if ($(STRINGS-Is-Empty "${__linker}") -eq 0) {
			$null = I18N-Sync-Register-Skipped-Missing-Linker
			continue
		}
	}}

	switch ($__os) { ### filter by OS
	darwin {
		if ("${env:PROJECT_OS}" -ne "darwin") {
			$null = I18N-Sync-Register-Skipped-Unsupported
			continue
		}
	} js {
		continue
	} windows {
		$__linker = "none"
	} fuchsia {
		$__linker = "none"
	} default {
	}}

	# execute
	$null = I18N-Import-Compiler "(RUST) ${__target}"
	$___process = OS-Exec "rustup" "target add `"${__target}`""
	if ($___process -ne 0) {
		$null = I18N-Import-Failed
		return 1
	}

	$null = FS-Append-File "${__parallel_directory}\parallel.txt" @"
${__target}|${__filename}|${__workspace}|${__source}|${__dest}|${__linker}|${__log}
"@
}

$___process = SYNC-Exec-Parallel `
	${function:SUBROUTINE-Build}.ToString() `
	"${__parallel_directory}\parallel.txt" `
	"${__parallel_directory}"
if ($___process -ne 0) {
	return 1
}




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




# compose documentations




# report status
return 0
