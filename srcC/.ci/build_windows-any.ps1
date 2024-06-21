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
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\c.ps1"




# execute
## define workspace configurations (avoid changes unless absolute necessary)
$__source_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}"
$__output_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$null = FS-Remake-Directory "${__output_directory}"

$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\build-${env:PROJECT_C}"
$null = FS-Make-Directory "${__log_directory}"

$__tmp_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}"
$null = FS-Make-Directory "${__tmp_directory}"

$__parallel_directory = "${__tmp_directory}\build-parallel-C"
$null = FS-Remake-Directory "${__parallel_directory}"

$__output_lib_directory = "${__tmp_directory}\build-lib${env:PROJECT_SKU}-C"
$null = FS-Remake-Directory "${__output_lib_directory}"


## define build targets
##
## Pattern: '[OS]|[ARCH]|[COMPILER]|[TYPE]|[CONTROL_FILE]'
##         (1) '[TYPE]'         - can either be 'executable' or 'library' only.
##         (2) '[CONTROL_FILE]' - the full filepath for a AutomataCI list of
##                                targets text file.
$__executable = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}\executable.txt"
$__library = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}\library.txt"
$__build_targets = @(
	"darwin|amd64|clang|executable|${__executable}"
	"darwin|amd64|clang|library|${__library}"
	"darwin|arm64|clang|executable|${__executable}"
	"darwin|arm64|clang|library|${__library}"
	"js|wasm|emcc|executable|${__executable}"
	"js|wasm|emcc|library|${__library}"
	"linux|amd64|x86_64-linux-gnu-gcc|executable|${__executable} "
	"linux|amd64|x86_64-linux-gnu-gcc|library|${__library}"
	"linux|arm64|aarch64-linux-gnu-gcc|executable|${__executable}"
	"linux|arm64|aarch64-linux-gnu-gcc|library|${__library}"
	"linux|armle|arm-linux-gnueabi-gcc|executable|${__executable}"
	"linux|armle|arm-linux-gnueabi-gcc|library|${__library}"
	"linux|armhf|arm-linux-gnueabihf-gcc|executable|${__executable}"
	"linux|armhf|arm-linux-gnueabihf-gcc|library|${__library}"
	"linux|mips|mips-linux-gnu-gcc|executable|${__executable}"
	"linux|mips|mips-linux-gnu-gcc|library|${__library}"
	"linux|mipsle|mipsel-linux-gnu-gcc|executable|${__executable}"
	"linux|mipsle|mipsel-linux-gnu-gcc|library|${__library}"
	"linux|mips64|mips64-linux-gnuabi64-gcc|executable|${__executable}"
	"linux|mips64|mips64-linux-gnuabi64-gcc|library|${__library}"
	"linux|mips64le|mips64el-linux-gnuabi64-gcc|executable|${__executable}"
	"linux|mips64le|mips64el-linux-gnuabi64-gcc|library|${__library}"
	"linux|mips64r6|mipsisa64r6-linux-gnuabi64-gcc|executable|${__executable}"
	"linux|mips64r6|mipsisa64r6-linux-gnuabi64-gcc|library|${__library}"
	"linux|mips64r6le|mipsisa64r6el-linux-gnuabi64-gcc|executable|${__executable}"
	"linux|mips64r6le|mipsisa64r6el-linux-gnuabi64-gcc|library|${__library}"
	"linux|powerpc|powerpc-linux-gnu-gcc|executable|${__executable}"
	"linux|powerpc|powerpc-linux-gnu-gcc|library|${__library}"
	"linux|ppc64le|powerpc64le-linux-gnu-gcc|executable|${__executable}"
	"linux|ppc64le|powerpc64le-linux-gnu-gcc|library|${__library}"
	"linux|riscv64|riscv64-linux-gnu-gcc|executable|${__executable}"
	"linux|riscv64|riscv64-linux-gnu-gcc|library|${__library}"
	"windows|amd64|x86_64-w64-mingw32-gcc|executable|${__executable}"
	"windows|amd64|x86_64-w64-mingw32-gcc|library|${__library}"
	"windows|arm64|x86_64-w64-mingw32-gcc|executable|${__executable}"
	"windows|arm64|x86_64-w64-mingw32-gcc|library|${__library}"
)


## NOTE: (1) Additional files like .h files, c source code files, assets files,
##           and etc to pack into library bulk.
##
##       (2) Basic package files like README.md and LICENSE.txt are not
##           required. The Package CI job will package it automatically in later
##           CI stage. Just focus on only the end-user consumption.
##
##       (3) Pattern: '[FULL_PATH]|[NEW_FILENAME]'
$__libs_files = @(
	"${__source_directory}\libs\greeters\Vanilla.h|lib${env:PROJECT_SKU}.h"
)


## NOTE: (1) C Compilers Optimization flags for known target OS and ARCH types.
function Get-Optimization-Flags {
	param(
		[string]$__target_os,
		[string]$__target_arch
	)


	switch ("${__target_os}") {
	darwin {
		$__arguments = "$(C-Get-Strict-Settings) -fPIC"
	} windows {
		$__arguments = " -Wall" `
			+ " -Wextra" `
			+ " -std=gnu89" `
			+ " -pedantic" `
			+ " -Wstrict-prototypes" `
			+ " -Wold-style-definition" `
			+ " -Wundef" `
			+ " -Wno-trigraphs" `
			+ " -fno-strict-aliasing" `
			+ " -fno-common" `
			+ " -fshort-wchar" `
			+ " -fno-stack-protector" `
			+ " -Werror-implicit-function-declaration" `
			+ " -Wno-format-security" `
			+ " -Os" `
			+ " -static"
	} default {
		$__arguments = "$(C-Get-Strict-Settings) -static -pie -fPIE"
	}}

	switch ("${__target_arch}") {
	{ $_ -in "armle", "armel", "armhf" } {
		$__arguments = " -Wall" `
			+ " -Wextra" `
			+ " -std=gnu89" `
			+ " -pedantic" `
			+ " -Wstrict-prototypes" `
			+ " -Wold-style-definition" `
			+ " -Wundef" `
			+ " -Wno-trigraphs" `
			+ " -fno-strict-aliasing" `
			+ " -fno-common" `
			+ " -fstack-protector-all" `
			+ " -Werror-implicit-function-declaration" `
			+ " -Wno-format-security" `
			+ " -Os" `
			+ " -static"
	} wasm {
		$__arguments = " -Wall" `
			+ " -Wextra" `
			+ " -std=gnu89" `
			+ " -pedantic" `
			+ " -Wstrict-prototypes" `
			+ " -Wold-style-definition" `
			+ " -Wundef" `
			+ " -Wno-trigraphs" `
			+ " -fno-strict-aliasing" `
			+ " -fno-common" `
			+ " -fshort-wchar" `
			+ " -fno-stack-protector" `
			+ " -Werror-implicit-function-declaration" `
			+ " -Wno-format-security" `
			+ " -Os" `
			+ " -static"
	} default {
		# no changes
	}}


	# report status
	return $__arguments
}


## NOTE: (1) perform any hard-coded overriding restrictions or gatekeeping
##           customization adjustments here (e.g. interim buggy compiler,
##           geo-politic distruption). By default, it is returning 0. Any
##           rejection shall return a non-zero value (e.g. 1).
function Check-Host-Can-Build-Target {
	switch ("${__target_os}-${__target_arch}") {
	default {
		# no issue by default
		return 0
	}}
}




# build algorithms - modify only when absolute necessary
function SUBROUTINE-Build {
	param(
		[string]$__line
	)


	# initialize
	. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
	. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
	. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
	. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
	. "${env:LIBS_AUTOMATACI}\services\compilers\c.ps1"


	# parse output
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		return 0
	}

	$__list = $__line -split "\|"
	$__file_output = $__list[0]
	$__file_sources = $__list[1]
	$__file_type = $__list[2]
	$__target_os = $__list[3]
	$__target_arch = $__list[4]
	$__target_compiler = $__list[5]
	$__arguments = $__list[6]
	$__output_directory = $__list[7]
	$__output_lib_directory = $__list[8]
	$__tmp_directory = $__list[9]
	$__log_directory = $__list[10]


	# validate input
	if (($(STRINGS-Is-Empty "${__file_output}") -eq 0) -or
		($(STRINGS-Is-Empty "${__file_sources}") -eq 0) -or
		($(STRINGS-Is-Empty "${__file_type}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_os}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_compiler}") -eq 0) -or
		($(STRINGS-Is-Empty "${__arguments}") -eq 0) -or
		($(STRINGS-Is-Empty "${__output_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${__output_lib_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${__tmp_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${__log_directory}") -eq 0)) {
		return 1
	}


	# prepare critical parameters
	$__target = "$(FS-Extension-Remove "$(FS-Get-File "${__file_output}")" "*")"
	$__workspace = "${__tmp_directory}\build-${__target}"
	$__log = "${__log_directory}\${__target}"
	$__file_output = "${__workspace}\$(FS-Get-File "${__file_output}")"

	$null = I18N-Build-Parallel "${__file_output}"
	$null = FS-Make-Directory "${__workspace}"
	$null = FS-Make-Directory "${__log}"
	$___process = C-Build "${__file_output}" `
			"${__file_sources}" `
			"${__file_type}" `
			"${__target_os}" `
			"${__target_arch}" `
			"${__workspace}" `
			"${__log}" `
			"${__target_compiler}" `
			"${__arguments}"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed-Parallel "${__file_output}"
		return 1
	}


	# export target
	$__dest = "${__output_directory}"
	if ("${__file_type}" -eq "library") {
		$__dest = "${__output_lib_directory}"
	}
	$__dest = "${__dest}\$(FS-Get-File "${__file_output}")"
	$null = FS-Remove-Silently "${__dest}"
	$___process = FS-Copy-File "${__file_output}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed-Parallel "${__file_output}"
		return 1
	}

	if ("${__target_os}-${__target_arch}" -eq "js-wasm") {
		$__source = "$(FS-Extension-Remove "${__file_output}" "*").js"
		if ($(FS-Is-File "${__source}") -eq 0) {
			$__dest = "$(FS-Extension-Remove "${__dest}" "*").js"
			$null = FS-Remove-Silently "${__dest}"
			$___process = FS-Move "${__source}" "${__dest}"
			if ($___process -ne 0) {
				$null = I18N-Build-Failed-Parallel "${__file_output}"
				return 1
			}
		}
	}


	# report status
	return 0
}


## register targets and execute parallel build
foreach ($__line in $__build_targets) {
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		continue
	}


	# parse target data
	$__list = $__line -split "\|"
	$__target_os = "$(STRINGS-To-Lowercase $__list[0])"
	$__target_arch = "$(STRINGS-To-Lowercase $__list[1])"
	$__target_compiler = $__list[2]
	$__target_type = $__list[3]
	$__source = $__list[4]


	# validate input
	switch ("${__target_type}") {
	{ $_ -in "elf", "exe", "executable" } {
		$__file_output = "${env:PROJECT_SKU}_${__target_os}-${__target_arch}"
		if (("${__target_os}" -eq "js") -and ("${__target_arch}" -eq "wasm")) {
			$__file_output = "${__file_output}.wasm"
		} elseif ("${__target_os}" -eq "windows") {
			$__file_output = "${__file_output}.exe"
		} else {
			$__file_output = "${__file_output}.elf"
		}
	} { $_ -in "lib", "dll", "library" } {
		$__file_output = "lib${env:PROJECT_SKU}_${__target_os}-${__target_arch}"
		if (("${__target_os}" -eq "js") -and ("${__target_arch}" -eq "wasm")) {
			$__file_output = "${__file_output}.wasm"
		} elseif ("${__target_os}" -eq "windows") {
			$__file_output = "${__file_output}.dll"
		} else {
			$__file_output = "${__file_output}.a"
		}
	} default {
		return 1
	}}
	$null = I18N-Sync-Register "${__file_output}"

	$___process = FS-Is-File "${__source}"
	if ($___process -ne 0) {
		$null = I18N-Sync-Failed
		return 1
	}

	if (($(STRINGS-Is-Empty "${__target_os}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_arch}") -eq 0)) {
		$null = I18N-Sync-Register-Skipped-Missing-Target
		continue
	}

	if ($(STRINGS-Is-Empty "${__target_compiler}") -eq 0) {
		$___process = OS-Is-Command-Available "${__target_compiler}"
		if ($___process -ne 0) {
			$null = I18N-Sync-Register-Skipped-Missing-Compiler
			continue
		}
	} else {
		$__target_compiler = "$(C-Get-Compiler `
			"${__target_os}" `
			"${__target_arch}" `
			"${env:PROJECT_OS}" `
			"${env:PROJECT_ARCH}"
		)"
		if ($(STRINGS-Is-Empty "${__target_compiler}") -eq 0) {
			$null = I18N-Sync-Register-Skipped-Missing-Compiler
			continue
		}
	}

	$___process = Check-Host-Can-Build-Target
	if ($___process -ne 0) {
		continue
	}

	$__arguments = "$(Get-Optimization-Flags "${__target_os}" "${__target_arch}")"


	# target is healthy - register into build list
	$null = FS-Append-File "${__parallel_directory}\parallel.txt" @"
${__file_output}|${__source}|${__target_type}|${__target_os}|${__target_arch}|${__target_compiler}|${__arguments}|${__output_directory}|${__output_lib_directory}|${__tmp_directory}|${__log_directory}

"@
}


## Execute the build
## NOTE: For some reason, the sync flag in parallel run is not free up at this
##       layer. The underlying layer (object files building) is in parallel run
##       and shall be given that priority.
##
##       Hence, we can only use serial run for the time being.
$___process = SYNC-Exec-Serial `
	${function:SUBROUTINE-Build}.ToString() `
	"${__parallel_directory}\parallel.txt" `
	"${__parallel_directory}"
if ($___process -ne 0) {
	return 1
}


## assemble additional library files
foreach ($__line in $__libs_files) {
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		continue
	}

	$__list = $__line -split "\|"


	# build the file
	$__source = $__list[0]
	$__dest = $__list[1]
	$__file = "${__output_lib_directory}\${__dest}"
	$null = I18N-Copy "${__source}" "${__dest}"
	$null = FS-Remove-Silently "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}
}


## export library package
$___process = FS-Is-Directory-Empty "${__output_lib_directory}"
if ($___process -ne 0) {
	$__dest = "${__output_directory}/lib${env:PROJECT_SKU}-C_any-any.tar.xz"

	$null = I18N-Export "${__dest}"
	$__current_path = Get-Location
	$null = Set-Location -Path "${__output_lib_directory}"
	$___process = TAR-Create-XZ "${__dest}" "."
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path
	if ($___process -ne 0) {
		$null = I18N-Export-Failed
		return 1
	}
}




# report status
return 0
