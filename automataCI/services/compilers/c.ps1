# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\sync.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\ar.ps1"




function C-Build {
	param(
		[string]$___file_output,
		[string]$___list_sources,
		[string]$___output_type,
		[string]$___target_os,
		[string]$___target_arch,
		[string]$___directory_workspace,
		[string]$___directory_log,
		[string]$___compiler,
		[string]$___arguments
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___file_output}") -eq 0) -or
		($(STRINGS-Is-Empty "${___list_sources}") -eq 0) -or
		($(STRINGS-Is-Empty "${___output_type}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target_os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target_arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___directory_workspace}") -eq 0) -or
		($(STRINGS-Is-Empty "${___directory_log}") -eq 0) -or
		($(STRINGS-Is-Empty "${___compiler}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arguments}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___list_sources}"
	if ($___process -ne 0) {
		return 1
	}

	$___directory_source = "$(FS-Get-Directory "${___list_sources}")"
	$___process = FS-Is-Directory "${___directory_source}"
	if ($___process -ne 0) {
		return 1
	}

	switch ("${___output_type}") {
	{ $_ -in "elf", "exe", "executable" } {
		# accepted - build .elf|.exe file
	} { $_ -in "lib", "dll", "library" } {
		# accepted - build .a|.dll file
	} "none" {
		# accepted - build .o objects
	} default {
		return 1
	}}

	$___process = AR-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___build_list = "${___directory_workspace}\build-list.txt"
	$___object_list = "${___directory_workspace}\object-list.txt"
	$null = FS-Remake-Directory "${___directory_workspace}"
	$null = FS-Remake-Directory "${___directory_log}"
	$null = FS-Remove-Silently "${___build_list}"
	$null = FS-Remove-Silently "${___object_list}"

	## (1) Scan for all files
	foreach ($__line in (Get-Content -Path "${___list_sources}")) {
		$__line = $__line -replace '#.*$', ''
		$__line = "$(STRINGS-Trim-Whitespace "${__line}")"
		if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
			continue
		}
		$__line = $__line -replace '/', '\'

		$___platform = $__line -replace ' .*$', ''
		$___file = $__line -replace '^.*\s', ''
		$___file_src = "${___directory_source}\${___file}"
		$___file_obj = "${___directory_workspace}\$(FS-Extension-Remove "${___file}" "*").o"
		$___file_log = "${___directory_log}\$(FS-Extension-Remove "${___file}" "*")_build.log"


		# check source code existence
		$___process = FS-Is-File "${___file_src}"
		if ($___process -ne 0) {
			return 1
		}


		# check source file compatibilities
		$___os = $___platform -replace '-.*$', ''
		$___arch = $___platform -replace '^.*-', ''
		if ($(STRINGS-Is-Empty "${___platform}") -ne 0) {
			# verify OS
			if ($___os -ne "any") {
				if ($___os -ne $___target_os) {
					continue
				}
			}

			# verify ARCH
			if ($___arch -ne "any") {
				if ($___arch -ne $___target_arch) {
					continue
				}
			}
		}
		$___os = "${___target_os}"
		$___arch = "${___target_arch}"


		# begin registrations
		if ("$(FS-Extension-Remove "${___file_src}" ".c")" -ne "${___file_src}") {
			# it's a .c file. Register for building and linking...
			$___process = FS-Append-File "${___build_list}" @"
build|${___file_obj}|${___file_src}|${___file_log}|${___os}|${___arch}|${___compiler}|${___arguments}

"@
			if ($___process -ne 0) {
				return 1
			}


			$___process = FS-Append-File "${___object_list}" "${___file_obj}`n"
			if ($___process -ne 0) {
				return 1
			}
		} elseif ("$(FS-Extension-Remove "${___file_src}" ".o")" -ne "${___file_src}") {
			# it's a .o file. Register only for linking...
			$null = FS-Make-Housing-Directory "${___file_obj}"

			$___process = FS-Copy-File "${___file_src}" "${___file_obj}"
			if ($___process -ne 0) {
				return 1
			}

			$___process = FS-Append-File "${___object_list}" "${___file_obj}`n"
			if ($___process -ne 0) {
				return 1
			}
		} else {
			# it's an unknown file. Bail out...
			return 1
		}
	}

	## (2) Bail early if object list is unavailable
	$___process = FS-Is-File "${___object_list}"
	if ($___process -ne 0) {
		return 0
	}

	## (3) Build all object files if found
	$___process = FS-Is-File "${___build_list}"
	if ($___process -eq 0) {
		$___process = SYNC-Exec-Parallel `
			${function:C-Run-Parallel}.ToString() `
			"${___build_list}" `
			"${___directory_workspace}"
		if ($___process -ne 0) {
			return 1
		}
	}

	## (4) Link all objects into the target
	$null = FS-Remove-Silently "${___file_output}"
	switch ("${___output_type}") {
	{ $_ -in "elf", "exe", "executable" } {
		$___arguments = ""
		foreach ($__line in (Get-Content -Path "${___object_list}")) {
			$___arguments = "${___arguments} ${__line}"
		}

		$___process = OS-Exec "${___compiler}" "-o ${___file_output} ${___arguments}"
		if ($___process -ne 0) {
			$null = FS-Remove-Silently "${___file_output}"
			return 1
		}
	} { $_ -in "lib", "dll", "library" } {
		foreach ($__line in (Get-Content -Path "${___object_list}")) {
			$___process = AR-Create "${___file_output}" "${__line}"
			if ($___process -ne 0) {
				$null = FS-Remove-Silently "${___file_output}"
				return 1
			}
		}
	} default {
		# assume to building only object file
	}}


	# report status
	return 0
}



function C-Get-Compiler {
	param(
		[string]$___os,
		[string]$___arch,
		[string]$___base_os,
		[string]$___base_arch,
		[string]$___compiler
	)


	# execute
	$null = OS-Sync

	if ($(STRINGS-Is-Empty "${___compiler}") -ne 0) {
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return "${___compiler}"
		}
	}

	switch ("${___os}-${___arch}") {
	{ $_ -in "darwin-amd64", "darwin-arm64" } {
		$___compiler = "clang-17"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "clang-15"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "clang-14"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "clang"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "js-wasm" {
		$___compiler = "emcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}
	} "linux-amd64" {
		$___compiler = "arm-linux-gnueabi-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-arm64" {
		$___compiler = "aarch64-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-arm", "linux-armel", "linux-armle" } {
		$___compiler = "arm-linux-gnueabi-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "arm-linux-eabi-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-armhf" {
		$___compiler = "arm-linux-gnueabihf-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-i386" {
		$___compiler = "i686-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "i686-elf-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-mips" {
		$___compiler = "mips-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mipsle", "linux-mipsel" } {
		$___compiler = "mipsel-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-mips64" {
		$___compiler = "mips64-linux-gnuabi64-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips64le", "linux-mips64el" } {
		$___compiler = "mips64el-linux-gnuabi64-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips32r6", "linux-mipsisa32r6" } {
		$___compiler = "mipsisa32r6-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips64r6", "linux-mipsisa64r6" } {
		$___compiler = "mipsisa64r6-linux-gnuabi64-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips32r6le", "linux-mipsisa32r6le", "linux-mipsisa32r6el" } {
		$___compiler = "mipsisa32r6el-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips64r6le", "linux-mipsisa64r6le", "linux-mipsisa64r6el" } {
		$___compiler = "mipsisa64r6el-linux-gnuabi64-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-powerpc" {
		$___compiler = "powerpc-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-ppc64le", "linux-ppc64el" } {
		$___compiler = "powerpc64le-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { "linux-riscv64" } {
		$___compiler = "riscv64-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "riscv64-elf-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { "linux-s390x" } {
		$___compiler = "s390x-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { "none-avr" } {
		$___compiler = "avr-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}
	} "windows-amd64" {
		$___compiler = "x86_64-w64-mingw32-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "mingw64"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}


		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "cc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "windows-i386" {
		$___compiler = "i686-w64-mingw32-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "mingw32"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}


		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "wasip1-wasm" {
		# let it fail
	} default {
		# let it fail
	}}


	# report status
	return ""
}




function C-Get-Strict-Settings {
	return " -Wall" `
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
		+ " -fstack-protector-all" `
		+ " -Werror-implicit-function-declaration" `
		+ " -Wno-format-security" `
		+ " -Os"
}




function C-Is-Available {
	# execute
	$null = OS-Sync
	$___process = C-Get-Compiler `
			"${env:PROJECT_OS}" `
			"${env:PROJECT_ARCH}" `
			"${env:PROJECT_OS}" `
			"${env:PROJECT_ARCH}"
	if ($(STRINGS-Is-Empty "${___process}") -eq 0) {
		return 1
	}


	# report status
	return 0
}




function C-Setup {
	# validate input
	$___process = C-Is-Available
	if ($___process -eq 0) {
		return 0
	}

	$___process =  OS-Is-Command-Available "choco"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "choco" "install gcc-arm-embedded -y"
	if ($___process -ne 0) {
		return 1
	}

	if (($(STRINGS-Is-Empty "$(C-Get-Compiler "windows" "amd64")") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_ROBOT_RUN}") -ne 0)) {
		$___process = OS-Exec "choco" "install mingw -y"
		if ($___process -ne 0) {
			return 1
		}
	}

	if (($(STRINGS-Is-Empty "$(C-Get-Compiler "js" "wasm")") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_ROBOT_RUN}") -ne 0)) {
		# BUG: choco fails to install emscripten's dependency properly (git.install)
		#      See: https://github.com/aminya/chocolatey-emscripten/issues/2
		#$___process = OS-Exec "choco" "install emscripten -y"
		#if ($___process -ne 0) {
		#	return 1
		#}
	}

	$null = OS-Sync


	# report status
	return 0
}




function C-Run-Parallel {
	param(
		[string]$___line
	)


	# initialize libraries from scratch
	. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
	. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
	. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
	. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"


	# parse input
	$___list = $___line.Split("|")
	$___mode = $___list[0]
	$___file_object = $___list[1]
	$___file_source = $___list[2]
	$___file_log = $___list[3]
	$___target_os = $___list[4]
	$___target_arch = $___list[5]
	$___compiler = $___list[6]
	$___arguments = $___list[7]


	# validate input
	if (($(STRINGS-Is-Empty "${___mode}") -eq 0) -or
		($(STRINGS-Is-Empty "${___file_object}") -eq 0) -or
		($(STRINGS-Is-Empty "${___file_source}") -eq 0) -or
		($(STRINGS-Is-Empty "${___file_log}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target_os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target_arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___compiler}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arguments}") -eq 0)) {
		return 1
	}

	$___mode = "$(STRINGS-To-Lowercase "${___mode}")"
	switch ("${___mode}") {
	{ $_ -in "build", "build-obj", "build-object" } {
		# accepted
	} { $_ -in "build-exe", "build-elf", "build-executable" } {
		# accepted
	} "test" {
		# accepted
	} default {
		return 1
	}}

	$null = FS-Make-Housing-Directory "${___file_object}"
	$null = FS-Make-Housing-Directory "${___file_log}"
	$null = FS-Remove-Silently "${___file_log}"

	if ("${___mode}" -eq "test") {
		$null = I18N-Test "${___file_object}" *>> "${___file_log}"
		if ("${___target_os}" -ne "${env:PROJECT_OS}") {
			$null = I18N-Test-Skipped *>> "${___file_log}"
			return 10 # skipped - cannot operate in host environment
		}

		$($___process = FS-Is-File "${___file_object}") *> "${___file_log}"
		if ($___process -ne 0) {
			$null = I18N-Test-Failed *>> "${___file_log}"
			return 1 # failed - build stage
		}

		$___process = OS-Exec `
			"${___file_object}" `
			"" `
			"$(FS-Extension-Remove "${___file_log}" ".log")-stdout.log" `
			"$(FS-Extension-Remove "${___file_log}" ".log")-stderr.log"
		if ($___process -ne 0) {
			$null = I18N-Test-Failed *>> "${___file_log}"
			return 1 # failed - test stage
		}


		# report status (test mode)
		return 0
	}


	# operate in build mode
	if ($(STRINGS-Is-Empty "${___compiler}") -eq 0) {
		$null = I18N-Build-Failed *>> "${___file_log}"
		return 1
	}

	switch ("${___mode}") {
	{ $_ -in "build-exe", "build-elf", "build-executable" } {
		$___arguments = @"
${___arguments} -o ${___file_object} ${___file_source}
"@

	} default {
		# assume to building object file
		$___arguments = @"
${___arguments} -o ${___file_object} -c ${___file_source}
"@
	}}

	$($null = I18N-Build "${___file_object}") *>> "${___file_log}"
	$___process = OS-Exec `
			"${___compiler}" `
			"${___arguments}" `
			"$(FS-Extension-Remove "${___file_log}" ".log")-stdout.log" `
			"$(FS-Extension-Remove "${___file_log}" ".log")-stderr.log"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed *>> "${___file_log}"
		return 1
	}


	# report status (build mode)
	return 0
}




function C-Test {
	param(
		[string]$___directory,
		[string]$___os,
		[string]$___arch,
		[string]$___arguments
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arguments}") -eq 0)) {
		return 1
	}

	$___process = C-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___compiler = "$(C-Get-Compiler `
		"${___os}" `
		"${___arch}" `
		"${env:PROJECT_OS}" `
		"${env:PROJET_ARCH}" `
	)"
	if ($(STRINGS-Is-Empty "${___compiler}") -eq 0) {
		return 1
	}


	# execute
	$___workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\test-${env:PROJECT_C}"
	$___log = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\test-${env:PROJECT_C}"
	$___build_list = "${___workspace}\build-list.txt"
	$___test_list = "${___workspace}\test-list.txt"
	$null = FS-Remake-Directory "${___workspace}"
	$null = FS-Remake-Directory "${___log}"

	## (1) Scan for all test files
	foreach ($___file_src in (Get-ChildItem -Path "${___directory}" `
			-Recurse `
			-Filter "*_test.c").FullName) {
		$___file_obj = "$(FS-Get-Path-Relative "${___file_src}" "${___directory}")"
		$___file_obj = "$(FS-Extension-Remove "${___file_obj}" "*")"
		$___file_log = "${___log}/${___file_obj}"
		switch ("${___os}") {
		"windows" {
			$___file_obj = "${___workspace}\${___file_obj}.exe"
		} default {
			$___file_obj = "${___workspace}\${___file_obj}.elf"
		}}


		$___process = FS-Append-File "${___build_list}" @"
build-executable|${___file_obj}|${___file_src}|${___file_log}_build.log|${___os}|${___arch}|${___compiler}|${___arguments}

"@
		if ($___process -ne 0) {
			return 1
		}

		$___process = FS-Append-File "${___test_list}" @"
test|${___file_obj}|${___file_src}|${___file_log}_test.log|${___os}|${___arch}|${___compiler}|${___arguments}

"@
		if ($___process -ne 0) {
			return 1
		}
	}

	## (2) Bail early if test is unavailable
	$___process = FS-Is-File "${___test_list}"
	if ($___process -ne 0) {
		return 0
	}

	## (3) Build all test artifacts
	$___process = FS-Is-File "${___build_list}"
	if ($___process -eq 0) {
		$___process = SYNC-Exec-Parallel `
			${function:C-Run-Parallel}.ToString() `
			"${___build_list}" `
			"${___workspace}"
		if ($___process -ne 0) {
			return 1
		}
	}

	## (4) Execute all test artifacts
	$___process = SYNC-Exec-Parallel `
		${function:C-Run-Parallel}.ToString() `
		"${___test_list}" `
		"${___workspace}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
