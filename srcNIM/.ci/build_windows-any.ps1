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
. "${env:LIBS_AUTOMATACI}\services\compilers\nim.ps1"




# execute
$null = I18N-Activate-Environment
$___process = NIM-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


$__output_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$null = FS-Remake-Directory "${__output_directory}"

$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}"
$null = FS-Make-Directory "${__log_directory}"

$__tmp_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}"
$null = FS-Make-Directory "${__tmp_directory}"

$__parallel_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\nim-parallel"
$null = FS-Make-Directory "${__parallel_directory}"


$__main = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}\${env:PROJECT_SKU}.nim"

$__build_targets = @(
	"darwin|amd64|clang|${__main}"
	"darwin|arm64|clang|${__main}"
	"js|wasm|emcc|${__main}"
	"js|js|native|${__main}"
	"linux|amd64|x86_64-linux-gnu-gcc|${__main}"
	"linux|arm64|aarch64-linux-gnu-gcc|${__main}"
	"linux|armle|arm-linux-gnueabi-gcc|${__main}"
	"linux|armhf|arm-linux-gnueabihf-gcc|${__main}"
	"linux|mips|mips-linux-gnu-gcc|${__main}"
	"linux|mipsle|mipsel-linux-gnu-gcc|${__main}"
	"linux|mips64|mips64-linux-gnuabi64-gcc|${__main}"
	"linux|mips64le|mips64el-linux-gnuabi64-gcc|${__main}"
	"linux|mips64r6|mipsisa64r6-linux-gnuabi64-gcc|${__main}"
	"linux|mips64r6le|mipsisa64r6el-linux-gnuabi64-gcc|${__main}"
	"linux|powerpc|powerpc-linux-gnu-gcc|${__main}"
	"linux|ppc64le|powerpc64le-linux-gnu-gcc|${__main}"
	"linux|riscv64|riscv64-linux-gnu-gcc|${__main}"
	"windows|amd64|x86_64-w64-mingw32-gcc|${__main}"
	"windows|arm64|x86_64-w64-mingw32-gcc|${__main}"
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
	. "${env:LIBS_AUTOMATACI}\services\compilers\nim.ps1"


	# parse output
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		return 0
	}

	$__list = $__line -split "\|"
	$__target_name = $__list[0]
	$__target_os = $__list[1]
	$__target_arch = $__list[2]
	$__target_compiler = $__list[3]
	$__dir_output = $__list[4]
	$__dir_workspace = $__list[5]
	$__dir_log = $__list[6]
	$__source = $__list[7]


	# validate input
	if (($(STRINGS-Is-Empty "${__target_name}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_os}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_compiler}") -eq 0) -or
		($(STRINGS-Is-Empty "${__dir_output}") -eq 0) -or
		($(STRINGS-Is-Empty "${__dir_workspace}") -eq 0) -or
		($(STRINGS-Is-Empty "${__dir_log}") -eq 0) -or
		($(STRINGS-Is-Empty "${__source}") -eq 0)) {
		return 1
	}

	if ("${__target_compiler}" -eq "native") {
		$__target_compiler = ""
	}


	# prepare critical parameters
	$__target = "${__target_name}_${__target_os}-${__target_arch}"
	$___arguments_c = " compileToC" `
		+ " --passC:-Wall --passL:-Wall" `
		+ " --passC:-Wextra --passL:-Wextra" `
		+ " --passC:-std=gnu89 --passL:-std=gnu89" `
		+ " --passC:-pedantic --passL:-pedantic" `
		+ " --passC:-Wstrict-prototypes --passL:-Wstrict-prototypes" `
		+ " --passC:-Wold-style-definition --passL:-Wold-style-definition" `
		+ " --passC:-Wundef --passL:-Wundef" `
		+ " --passC:-Wno-trigraphs --passL:-Wno-trigraphs" `
		+ " --passC:-fno-strict-aliasing --passL:-fno-strict-aliasing" `
		+ " --passC:-fno-common --passL:-fno-common" `
		+ " --passC:-fshort-wchar --passL:-fshort-wchar" `
		+ " --passC:-fstack-protector-all --passL:-fstack-protector-all" `
		+ " --passC:-Werror-implicit-function-declaration --passL:-Werror-implicit-function-declaration" `
		+ " --passC:-Wno-format-security --passL:-Wno-format-security" `
		+ " --passC:-Os --passL:-Os" `
		+ " --passC:-g0 --passL:-g0" `
		+ " --passC:-flto --passL:-flto" `
		+ " --passC:-s --passL:-s" `
		+ " --passC:-static --passL:-static" `
		+ " --passC:-fPIC"

	$___arguments_nim = " --mm:orc" `
		+ " --define:release" `
		+ " --opt:size" `
		+ " --colors:on" `
		+ " --styleCheck:off" `
		+ " --showAllMismatches:on" `
		+ " --tlsEmulation:on" `
		+ " --implicitStatic:on" `
		+ " --trmacros:on" `
		+ " --panics:on"

	switch ("${__target_os}-${__target_arch}") {
	"darwin-amd64" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:clang" `
			+ " --amd64.MacOS.clang.exe=`"${__target_compiler}`"" `
			+ " --amd64.MacOS.clang.linkerexe=`"${__target_compiler}`"" `
			+ " --cpu:amd64"
	} "darwin-arm64" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:clang" `
			+ " --arm64.MacOS.clang.exe=`"${__target_compiler}`"" `
			+ " --arm64.MacOS.clang.linkerexe=`"${__target_compiler}`"" `
			+ " --cpu:arm64"
	} "js-js" {
		$__arguments = "js ${___arguments_nim}"
	} "js-wasm" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ "--define:emscripten"
	} "linux-amd64" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --amd64.linux.gcc.exe=`"${__target_compiler}`"" `
			+ " --amd64.linux.gcc.linkerexe=`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:amd64"
	} "linux-arm64" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --arm64.linux.gcc.exe=`"${__target_compiler}`"" `
			+ " --arm64.linux.gcc.linkerexe=`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:arm64"
	} { $_ -in "linux-armel", "linux-armle" } {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --arm.linux.gcc.exe=`"${__target_compiler}`"" `
			+ " --arm.linux.gcc.linkerexe=`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:arm"
	} "linux-armhf" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --arm.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --arm.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:arm"
	} "linux-mips" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --mips.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --mips.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:mips"
	} { $_ -in "linux-mipsle", "linux-mipsel" } {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --mipsel.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --mipsel.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:mipsel"
	} "linux-mips64" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --mips64.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --mips64.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:mips64"
	} { $_ -in "linux-mips64le", "linux-mips64el" } {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --mips64el.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --mips64el.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:mips64el"
	} "linux-mips64r6" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --mips64.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --mips64.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:mips64"
	} { $_ -in "linux-mips64r6le", "linux-mips64r6el" } {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --mips64el.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --mips64el.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:mips64el"
	} "linux-powerpc" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --powerpc.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --powerpc.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:powerpc"
	} { $_ -in "linux-ppc64le", "linux-ppc64el" } {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --powerpc64el.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --powerpc64el.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:powerpc64el"
	} "linux-riscv64" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --riscv64.linux.gcc.exe:`"${__target_compiler}`"" `
			+ " --riscv64.linux.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:linux" `
			+ " --cpu:riscv64"
	} "windows-amd64" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --amd64.windows.gcc.exe:`"${__target_compiler}`"" `
			+ " --amd64.windows.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:windows" `
			+ " --cpu:amd64"
	} "windows-arm64" {
		$__arguments = $___arguments_c `
			+ $___arguments_nim `
			+ " --cc:gcc" `
			+ " --arm64.windows.gcc.exe:`"${__target_compiler}`"" `
			+ " --arm64.windows.gcc.linkerexe:`"${__target_compiler}`"" `
			+ " --os:windows" `
			+ " --cpu:arm64"
	} default {
		$null = I18N-Build-Failed-Parallel "${__target}"
		return 1
	}}

	$__log = "${__dir_log}\bin\${__target}.log"
	switch ("${__target_os}-${__target_arch}") {
	{ $_ -match "^windows-.*" } {
		$__output = "${__dir_workspace}\bin\${__target}.exe"
	} "js-wasm" {
		$__output = "${__dir_workspace}\bin\${__target}.wasm"
	} "js-js" {
		$__output = "${__dir_workspace}\bin\${__target}.js"
	} default {
		$__output = "${__dir_workspace}\bin\${__target}.elf"
	}}


	# NOTE: Nim 2.0.2 has internal issue preventing parallel build. Hence,
	#       we have to disable the Parallel I18N to avoid miscommunications.
	$null = I18N-Build "${__target}"
	#$null = I18N-Build-Parallel "${__subject}"
	$null = FS-Remake-Directory "${__dir_workspace}"
	$null = FS-Make-Housing-Directory "${__log}"
	$null = FS-Remove-Silently "${__output}"
	$null = FS-Remove-Silently "${__log}"
	$___process = OS-Exec "nim" `
		"${__arguments} --out:${__output} ${__source}" `
		"$(FS-Extension-Remove "${__log}" "*")-stdout.log" `
		"$(FS-Extension-Remove "${__log}" "*")-stderr.log"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed-Parallel "${__target}"
		return 1
	}


	# export target
	$__dest = "${__dir_output}\$(FS-Get-File "${__output}")"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed-Parallel "${__target}"
		return 1
	}

	if ("${__target_os}-${__target_arch}" -eq "js-wasm") {
		if ($(FS-Is-File "$(FS-Extension-Remove "${__output}" "*").js") -eq 0) {
			$__dest = "$(FS-Extension-Remove "${__dest}" "*").js"
			$null = FS-Remove-Silently "${__dest}"
			$___process = FS-Move `
				"$(FS-Extension-Remove "${__dest}" "*").js" `
				"${__dest}"
			if ($___process -ne 0) {
				$null = I18N-Build-Failed-Parallel "${__target}"
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
	$__source = $__list[3]


	# validate input
	$null = I18N-Sync-Register "${__target_os}-${__target_arch}"
	if (($(STRINGS-Is-Empty "${__target_os}") -eq 0) -or
		($(STRINGS-Is-Empty "${__target_arch}") -eq 0)) {
		$null = I18N-Sync-Register-Skipped-Missing-Target
		continue
	}

	if ("${__target_os}-${__target_arch}" -eq "js-js") {
		$__target_compiler = "native"
	} elseif ($(STRINGS-Is-Empty "${__target_compiler}") -eq 0) {
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

	$__dir_tag = "build-${env:PROJECT_SKU}_${__target_os}-${__target_arch}"
	$__dir_workspace = "${__tmp_directory}\${__dir_tag}"
	$__dir_log = "${__log_directory}\${__dir_tag}"

	# execute
	$null = FS-Append-File "${__parallel_directory}\parallel.txt" @"
${env:PROJECT_SKU}|${__target_os}|${__target_arch}|${__target_compiler}|${__output_directory}|${__dir_workspace}|${__dir_log}|${__source}
"@
}


# IMPORTANT: Nim cannot perform parallel build due to internal limitations.
#            Hence, we cannot use 'SYNC_Exec_Parallel' for the time being.
$___process = SYNC-Exec-Parallel `
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
