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




# execute
$__output_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$null = FS-Remake-Directory "${__output_directory}"

$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}"
$null = FS-Make-Directory "${__log_directory}"

$__tmp_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}"
$null = FS-Make-Directory "${__tmp_directory}"

$__parallel_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\c-parallel"
$null = FS-Remake-Directory "${__parallel_directory}"

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

$__placeholders = @(
	"${env:PROJECT_SKU}-src_any-any"
	"${env:PROJECT_SKU}-homebrew_any-any"
	"${env:PROJECT_SKU}-chocolatey_any-any"
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


	# validate input
	if (($(STRINGS-Is-Empty "${__file_output}") -eq 0) -or
		($(STRINGS-Is-Empty "${__file_sources}") -eq 0) -or
		($(STRINGS-Is-Empty "${__file_type}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_os}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_compiler}") -eq 0) -or
		($(STRINGS-Is-Empty "${__arguments}") -eq 0)) {
		return 1
	}


	# prepare critical parameters
	$__target = "$(FS-Extension-Remove "$(FS-Get-File "${__file_output}")" "*")"
	$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\build-${__target}"
	$__log = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\build-${__target}"
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
	$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\$(FS-Get-File "${__file_output}")"
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




# register targets and execute parallel build
foreach ($__line in $__build_targets) {
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		continue
	}


	# parse target data
	$__list = $__line -split "\|"
	$__target_os = "$(STRINGS-To-Lowercase $__list[0])"
	$__target_arch = "$(STRINGS-To-Lowercase $__list[1])"
	$__target_compiler = $__list[2]
	$__target_compiler = $__list[3]
	$__source = $__list[4]


	# validate input
	switch ("${__target_type}") {
	{ $_ -in "elf", "exe", "executable" } {
		$__file_output = "${env:PROJECT_SKU}_${__target_os}-${__target_arch}"
		if ("${__target_os}" -eq "windows") {
			$__file_output = "${__file_output}.exe"
		} else {
			$__file_output = "${__file_output}.elf"
		}
	} { $_ -in "lib", "dll", "library" } {
		$__file_output = "lib${env:PROJECT_SKU}_${__target_os}-${__target_arch}"
		if ("${__target_os}" -eq "windows") {
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
		$__target_compiler = "$(C-Get-Compiler "${__target_os}" "${__target_arch}")"
		if ($(STRINGS-Is-Empty "${__target_compiler}") -eq 0) {
			$null = I18N-Sync-Register-Skipped-Missing-Compiler
			continue
		}
	}


	## NOTE: perform any hard-coded host system restrictions or gatekeeping
	##       customization adjustments here.
	switch ("${__target_os}-${__target_arch}") {
	default {
		# accepted
	}}


	# formulate compiler optimization flags
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
		$__arguments = "$(C-Get-Strict-Settings) -pie -fPIE"
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


	# target is healthy - register into build list
	$null = FS-Append-File "${__parallel_directory}\parallel.txt" @"
${__file_output}|${__source}|${__target_type}|${__target_os}|${__target_arch}|${__target_compiler}|${__arguments}
"@
}


# NOTE: For some reason, the sync flag in parallel run is not free up at this
#       layer. The underlying layer (object files building) is in parallel run
#       and shall be given that priority.
#
#       Hence, we can only use serial run for the time being.
$___process = SYNC-Exec-Serial `
	${function:SUBROUTINE-Build}.ToString() `
	"${__parallel_directory}\parallel.txt" `
	"${__parallel_directory}"
if ($___process -ne 0) {
	return 1
}




# placeholding flag files
foreach ($__line in $__placeholders) {
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		continue
	}


	# build the file
	$__file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__line}"
	$null = I18N-Build "${__line}"
	$null = FS-Remove-Silently "${__file}"
	$___process = FS-Touch-File "${__file}"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed
		return 1
	}
}




# compose documentations




# report status
return 0
