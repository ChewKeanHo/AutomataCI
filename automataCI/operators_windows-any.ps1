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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\sync.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\c.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\nim.ps1"




function BUILD-__Exec-Compile-Source-Code {
	# execute
	OS-Print-Status info "executing ${args}"
	$__process = Invoke-Expression "$args"
	if ($LASTEXITCODE -ne 0) {
		OS-Print-Status error "build failed.`n"
		return 1
	}


	# report status
	return 0
}




function BUILD-__Init-Sync {
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\sync.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\c.ps1"
	. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\nim.ps1"
}




function BUILD-__Validate-Config-File {
	param(
		[string]$_target_config,
		[string]$_target_source
	)


	# execute
	$__process = FS-Is-File `
		"${env:PROJECT_PATH_ROOT}\${_target_source}\${_target_config}"
	if ($__process -eq 0) {
		return "${env:PROJECT_PATH_ROOT}\${_target_source}\${_target_config}"
	} elseif (-not ($_target_config -match "${env:PROJECT_PATH_ROOT}")) {
		return "${_target_config}"
	}


	# report status
	return ""
}




function BUILD-__Validate-Source-Files {
	param(
		[string]$_target_config,
		[string]$_target_source,
		[string]$_target_compiler,
		[string]$_target_args,
		[string]$_target_directory,
		[string]$_linker_control,
		[string]$_target_os,
		[string]$_target_arch
	)


	# execute
	$_parallel_total = 0
	foreach ($__line in (Get-Content -Path "${_target_config}")) {
		$__line = $__line -replace '#.*$', ''
		if ([string]::IsNullOrEmpty($__line)) {
			continue
		}
		$__line = $__line -replace '/', '\'


		# check source code existence
		$__path = "${env:PROJECT_PATH_ROOT}\${_target_source}"
		$__path = "${__path}\$($__line -replace '^.*\s', '')"
		OS-Print-Status info "validating source file: ${__path}"
		$__process = FS-Is-File "${__path}"
		if ($__process -ne 0) {
			OS-Print-Status error "validation failed.`n"
			return
		}


		# check source code compatibilities
		$__os = $__line -replace ' .*$'
		$__arch = $__os -replace '.*-'
		$__os = $__os -replace '-.*'

		if (($__os -ne $_target_os) -and ($__os -ne "any")) {
			continue
		}

		if (($__arch -ne $_target_arch) -and ($__arch -ne "any")) {
			continue
		}


		# properly process path
		$__path = ($__line -split " ")[-1]
		if ((Split-Path $__path -Parent) -eq $__path) {
			$null = FS-Make-Directory "${_target_directory}"
		} else {
			$null = FS-Make-Directory `
				"${_target_directory}\$(Split-Path $__path -Parent)"
		}


		# create command for parallel execution
		if ($__path -match "\.c$") {
			OS-Print-Status info "registering .c file..."
			$__str = "{0} -o {1} -c {2} {3}" -f `
				${_target_compiler}, `
				"${_target_directory}\$($__path -replace '.c.*', '.o')", `
				"${env:PROJECT_PATH_ROOT}\${_target_source}\${__path}", `
				"${_target_args}"
			$__process = FS-Append-File "${_parallel_control}" "${__str}"
			if ($__process -ne 0) {
				OS-Print-Status error "register failed.`n"
				return 1
			}

			$__process = FS-Append-File "${_linker_control}" @"
${_target_directory}\$($__path -replace '.c.*', '.o')
"@
			if ($__process -ne 0) {
				OS-Print-Status error "register failed.`n"
				return
			}
		} elseif ($__path -match "\.nim$") {
			OS-Print-Status info "registering .nim file..."
			$__str = "{0} {1} --out:{2} {3}" -f `
				"${_target_compiler}", `
				"${_target_args}", `
				"${_target_directory}\$($__path -replace '.nim.*', '')", `
				"${env:PROJECT_PATH_ROOT}\${_target_source}\${__path}"
			$__process = FS-Append-File "${_parallel_control}" "${__str}"
			if ($__process -ne 0) {
				OS-Print-Status error "register failed.`n"
				return 1
			}

			$__process = FS-Append-File "${_linker_control}" @"
${_target_directory}\$($__path -replace '.nim.*', '')
"@
			if ($__process -ne 0) {
				OS-Print-Status error "register failed.`n"
				return
			}
		} elseif ($__path -match "\.o$") {
			OS-Print-Status info "registering .o file..."
			$__target_path = "${_target_directory}\${__path}"
			$null = FS-Make-Housing-Directory "${__target_path}"
			$__process = FS-Copy-File `
				"${env:PROJECT_PATH_ROOT}\${_target_source}\${__path}" `
				"$(Split-Path -Path $__target_path -Parent)"
			if ($__process -ne 0) {
				OS-Print-Status error "register failed.`n"
				return
			}

			$__process = FS-Append-File "${_linker_control}" @"
${_target_directory}\${__path}
"@
			if ($__process -ne 0) {
				OS-Print-Status error "register failed.`n"
				return
			}
		} else {
			OS-Print-Status info "unsupported file: ${__path}`n"
			return
		}

		$_parallel_total += 1
	}


	# report status
	return $_parallel_total
}




function BUILD-_Exec-Compile {
	param(
		[string]$_parallel_control,
		[string]$_target_directory
	)


	# execute
	$_parallel_available = [System.Environment]::ProcessorCount
	if ($_parallel_available -le 0) {
		$_parallel_available = 1
	}

	OS-Print-Status info "begin parallel building with ${_parallel_available} threads..."
	$__process = SYNC-Parallel-Exec `
		"BUILD-__Exec-Compile-Source-Code" `
		"${_parallel_control}" `
		"${_target_directory}" `
		"${_parallel_available}" `
		BUILD-__Init-Sync
	if ($__process -ne 0) {
		OS-Print-Status error "Build failed.`n"
		return 1
	}


	# report status
	return 0
}




function BUILD-_Exec-Build {
	param(
		[string]$_target_type,
		[string]$_target_os,
		[string]$_target_arch,
		[string]$_target_config,
		[string]$_target_args,
		[string]$_target_compiler
	)


	OS-Print-Status info "validating ${_target_os}-${_target_arch} ${_target_type}..."
	$_target = "${env:PROJECT_SKU}_${_target_os}-${_target_arch}"
	$_target_arch = STRINGS-To-Lowercase "${_target_arch}"
	$_target_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}"
	$_target_type = STRINGS-To-Lowercase "${_target_type}"
	switch ($_target_type) {
	nim-binary {
		$_target_source = "${env:PROJECT_NIM}"
		$_target_type = "none"
		$_target_directory = "${_target_directory}\nim-bin_${_target}"
		$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${_target}"
		$_target_compiler = "nim"
	} nim-test {
		$_target_source = "${env:PROJECT_NIM}"
		$_target_type = "none"
		$_target_directory = "${_target_directory}\nim-test_${_target}"
		$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${_target}"
		$_target_compiler = "nim"
	} c-binary {
		$_target_source = "${env:PROJECT_C}"
		$_target_type = "bin"
		$_target_directory = "${_target_directory}\c-bin_${_target}"
		switch ($_target_arch) {
		wasm {
			$_target = "${_target}.wasm"
		} default {
			$_target = "${_target}.exe"
		}}
		$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${_target}"
		$_target_compiler = C-Get-Compiler `
			"${_target_os}" `
			"${_target_arch}" `
			"${env:PROJECT_OS}" `
			"${env:PROJECT_ARCH}" `
			"${_target_compiler}"
		if ([string]::IsNullOrEmpty($_target_compiler)) {
			OS-Print-Status warning "No available compiler. Skipping...`n"
			return 10
		} else {
			OS-Print-Status info "selected ${_target_compiler} compiler..."
		}
	} c-library {
		$_target_source = "${env:PROJECT_C}"
		$_target_type = "lib"
		$_target = "${env:PROJECT_SKU}-lib_${_target_os}-${_target_arch}"
		$_target_directory = "${_target_directory}\c-lib_${_target}"
		$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${_target}.dll"
		$_target_compiler = C-Get-Compiler `
			"${_target_os}" `
			"${_target_arch}" `
			"${env:PROJECT_OS}" `
			"${env:PROJECT_ARCH}" `
			"${_target_compiler}"
		if ([string]::IsNullOrEmpty($_target_compiler)) {
			OS-Print-Status warning "No available compiler. Skipping...`n"
			return 10
		} else {
			OS-Print-Status info "selected ${_target_compiler} compiler..."
		}
	} c-test {
		$_target_source = "${env:PROJECT_C}"
		$_target_type = "test-bin"
		$_target_directory = "${_target_directory}\c-test_${_target}"
		$_target = "${_target_directory}"
		$_target_compiler = C-Get-Compiler `
			"${_target_os}" `
			"${_target_arch}" `
			"${env:PROJECT_OS}" `
			"${env:PROJECT_ARCH}" `
			"${_target_compiler}"
		if ([string]::IsNullOrEmpty($_target_compiler)) {
			OS-Print-Status warning "No available compiler. Skipping...`n"
			return 10
		} else {
			OS-Print-Status info "selected ${_target_compiler} compiler..."
		}
	} default {
		OS-Print-Status error "validation failed.`n"
		return 1
	}}
	$_parallel_control = "${_target_directory}\sync.txt"
	$_linker_control = "${_target_directory}\o-list.txt"
	$_parallel_total = 0


	OS-Print-Status info `
	"validating config file ($(Split-Path -Path "${_target_config}" -Leaf)) existence..."
	$_target_config = BUILD-__Validate-Config-File "${_target_config}" "${_target_source}"
	if ([string]::IsNullOrEmpty($_target_config)) {
		OS-Print-Status error "validation failed.`n"
		return 1
	}


	OS-Print-Status info "preparing ${_target} parallel build workspace..."
	$null = FS-Remove-Silently "${_parallel_control}"
	$null = FS-Remove-Silently "${_linker_control}"
	$null = FS-Remove-Silently `
		"${_target_directory}\~$(Split-Path -Leaf -Path "${_linker_control}")"


	$_parallel_total = BUILD-__Validate-Source-Files `
		"${_target_config}" `
		"${_target_source}" `
		"${_target_compiler}" `
		"${_target_args}" `
		"${_target_directory}" `
		"${_linker_control}" `
		"${_target_os}" `
		"${_target_arch}"
	if ([string]::IsNullOrEmpty($_parallel_total)) {
		return 1
	} elseif ($_parallel_total -eq 0) {
		return 1
	}


	# compile all object files
	$__process = BUILD-_Exec-Compile "${_parallel_control}" "${_target_directory}"
	if ($__process -ne 0) {
		return 1
	}


	# link all objects
	$__process = BUILD-_Exec-Link `
		"${_target_type}" `
		"${_target}" `
		"${_target_directory}" `
		"${_linker_control}" `
		"${_target_compiler}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function BUILD-_Exec-Link {
	param(
		[string]$_target_type,
		[string]$_target,
		[string]$_target_directory,
		[string]$_linker_control,
		[string]$_target_compiler
	)


	# validate input
	OS-Print-Status info "checking linking control file (${_linker_control})..."
	$__process = FS-Is-File "${_linker_control}"
	if ($__process -ne 0) {
		OS-Print-Status error "check failed.`n"
		return 1
	}


	# link all objects
	switch ($_target_type) {
	none {
		OS-Print-Status info "linking object file into executable..."
	} test-bin {
		OS-Print-Status info "linking object file into executable..."
		foreach ($__line in (Get-Content -Path "${_linker_control}")) {
			$_target = $__line -replace '\.o$', '.exe'
			$__process = FS-Remove-Silently "${_target}"
			if ($__process -ne 0) {
				OS-Print-Status error "link failed.`n"
				return 1
			}

			$__process = OS-Exec `
				"${_target_compiler}" `
				"-o `"${_target}`" `"${__line}`""
			if ($__process -ne 0) {
				OS-Print-Status error "link failed.`n"
				return 1
			}

			$__process = FS-Remove-Silently "${__line}"
			if ($__process -ne 0) {
				OS-Print-Status error "link failed.`n"
				return 1
			}
		}
	} bin {
		OS-Print-Status info "linking all object files into executable..."
		$__process = FS-Remove-Silently "${_target}"
		if ($__process -ne 0) {
			OS-Print-Status error "link failed.`n"
			return 1
		}

		$__directory = Split-Path -Parent -Path "${_linker_control}"
		$__file = Split-Path -Leaf -Path "${_linker_control}"
		$_linker_control = "${__directory}\~${__file}"
		foreach ($__line in (Get-Content -Path "${__directory}\${__file}")) {
			$__line = $__line -replace '\\', '/'
			$null = FS-Append-File "${_linker_control}" "${__line}"
		}

		$__process = OS-Exec `
			"${_target_compiler}" "-o `"${_target}`" @`"${_linker_control}`""
		if ($__process -ne 0) {
			OS-Print-Status error "link failed.`n"
			return 1
		}
	} lib {
		$__process = FS-Remove-Silently "${_target}"
		if ($__process -ne 0) {
			OS-Print-Status error "link failed.`n"
			return 1
		}

		foreach ($__line in (Get-Content -Path "${_linker_control}")) {
			OS-Print-Status info "linking into library ${__line}"
			$__process = OS-Exec "ar" "-rc `"${_target}`" `"${__line}`""
			if ($__process -ne 0) {
				OS-Print-Status error "link failed.`n"
				return 1
			}
		}
	} default {
		return 1
	}}


	# report status
	return 0
}




function BUILD-Compile {
	param(
		[string]$_target_type,
		[string]$_target_os,
		[string]$_target_arch,
		[string]$_target_config,
		[string]$_target_args,
		[string]$_target_compiler
	)


	# execute
	$null = FS-Make-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
	$__process = BUILD-_Exec-Build `
		"${_target_type}" `
		"${_target_os}" `
		"${_target_arch}" `
		"${_target_config}" `
		"${_target_args}" `
		"${_target_compiler}"
	if ($__process -eq 10) {
		return 10
	} elseif ($__process -ne 0) {
		return 1
	}


	# report status
	OS-Print-Status success "`n"
	return 0
}




function BUILD-Test {
	param(
		[string]$_target_type,
		[string]$_target_os,
		[string]$_target_arch,
		[string]$_target_args,
		[string]$_target_compiler
	)


	# prepare test environment
	$_target = "${env:PROJECT_SKU}_${_target_os}-${_target_arch}"
	$_target_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}"


	# scan for all test source codes
	OS-Print-Status info "setup test workspace..."
	$null = FS-Remake-Directory "${_target_directory}"
	switch ($_target_type) {
	"${env:PROJECT_NIM}" {
		OS-Print-Status info "scanning all nim test codes..."
		$_target_code = "nim-test"
		$_target_directory = "${_target_directory}\${_target_code}_${_target}"
		$_target_build_list = "${_target_directory}\build-list.txt"

		$null = FS-Remake-Directory "${_target_directory}"

		foreach ($__line in (Get-ChildItem `
			-Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}" `
			-Recurse `
			-Filter "*_test.nim").FullName) {
			$__line = $__line.Replace("${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}\", "")

			OS-Print-Status info "registering ${__line}"
			$null = FS-Append-File `
				"${_target_build_list}" `
				"${_target_os}-${_target_arch} ${__line}"
		}
	} "${env:PROJECT_C}" {
		OS-Print-Status info "scanning all C test codes..."
		$_target_code = "c-test"
		$_target_directory = "${_target_directory}\${_target_code}_${_target}"
		$_target_build_list = "${_target_directory}\build-list.txt"

		$null = FS-Remake-Directory "${_target_directory}"

		foreach ($__line in (Get-ChildItem `
			-Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}" `
			-Recurse `
			-Filter "*_test.c").FullName) {
			$__line = $__line.Replace("${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}\", "")
			OS-Print-Status info "registering ${__line}"
			$null = FS-Append-File `
				"${_target_build_list}" `
				"${_target_os}-${_target_arch} ${__line}"
		}

	} Default {
		OS-Print-Status error "unsupported tech."
		return 1
	}}


	# check if no test is available, get out early
	if (-not (Test-Path -Path "${_target_build_list}")) {
		OS-Print-Status success "`n"
		return 0
	}


	# build all test artifacts
	$__process = BUILD-_Exec-Build `
		"${_target_code}" `
		"${_target_os}" `
		"${_target_arch}" `
		"${_target_build_list}" `
		"${_target_args}" `
		"${_target_compiler}"
	if ($__process -eq 10) {
		return 10
	} elseif ($__process -ne 0) {
		return 1
	}


	# execute all test artifacts
	$_target_config = "${env:PROJECT_SKU}_${env:PROJECT_OS}-${env:PROJECT_ARCH}"
	$_target_config = "${_target_code}_${_target_config}"
	$_target_config = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${_target_config}"
	$_target_config = "${_target_config}\o-list.txt"

	OS-Print-Status info "checking test execution workspace..."
	$__process = FS-Is-File "${_target_config}"
	if ($__process -ne 0) {
		OS-Print-Status error "check failed - missing compatible workspace."
	}

	$EXIT_CODE = 0
	foreach ($__line in (Get-Content -Path "${_target_config}")) {
		$__line = $__line -replace '\.o$', '.exe'
		OS-Print-Status info "testing ${__line}"

		try {
			$null = Write-Host "$(Invoke-Expression "${__line}")"
			if ($LASTEXITCODE -ne 0) {
				$EXIT_CODE = 1
			}
		} catch {
			$EXIT_CODE = 1
		}
	}


	# report status
	if ($EXIT_CODE -ne 0) {
		OS-Print-Status error "test failed.`n"
		return 1
	}

	OS-Print-Status success "`n"
	return 0
}




# report status
return 0
