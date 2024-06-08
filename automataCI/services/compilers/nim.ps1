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




function NIM-Activate-Local-Environment {
	# validate input
	$___process = NIM-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = NIM-Is-Localized
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___location = "$(NIM-Get-Activator-Path)"
	if ($(FS-Is-File "${___location}") -ne 0) {
		return 1
	}

	. $___location

	$___process = NIM-Is-Localized
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NIM-Check-Package {
	param(
		[string]$___directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___directory}") -eq 0) {
		return 1
	}


	# execute
	$___current_path = Get-Location
	$null = Set-Location "${___directory}"
	$___process = OS-Exec "nimble" "check"
	$null = Set-Location "${___current_path}"
	$null = Remove-Variable ___current_path
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NIM-Get-Activator-Path {
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${env:PROJECT_PATH_NIM_ENGINE}\Activate.ps1"
}




function NIM-Is-Available {
	# execute
	$null = OS-Sync

	$___process = OS-Is-Command-Available "nim"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "nimble"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NIM-Is-Localized {
	# execute
	if ($(STRINGS-Is-Empty "${env:PROJECT_NIM_LOCALIZED}") -ne 0) {
		return 0
	}


	# report status
	return 1
}




function NIM-Run-Parallel {
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
	$___directory_source = $___list[1]
	$___directory_workspace = $___list[2]
	$___directory_log = $___list[3]
	$___target = $___list[4]
	$___target_os = $___list[5]
	$___target_arch = $___list[6]
	$___arguments = $___list[7]


	# validate input
	if (($(STRINGS-Is-Empty "${___mode}") -eq 0) -or
		($(STRINGS-Is-Empty "${___directory_source}") -eq 0) -or
		($(STRINGS-Is-Empty "${___directory_workspace}") -eq 0) -or
		($(STRINGS-Is-Empty "${___directory_log}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target_os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target_arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arguments}") -eq 0)) {
		return 1
	}

	$___mode = "$(STRINGS-To-Lowercase "${___mode}")"
	switch ("${___mode}") {
	{ $_ -in "build", "test" } {
		# accepted
	} default {
		return 1
	}}

	$___target = FS-Get-Path-Relative "${___target}" "${___directory_source}"
	$___directory_target = "$(FS-Get-Directory "${___target}")"
	$___file_target = "$(FS-Get-File "${___target}")"

	$___file_log = "${___directory_log}"
	$___file_output = "${___directory_workspace}"
	if ("${___directory_target}" -ne "${___file_target}") {
		# there are sub-directories
		$___file_log = "${___file_log}\${___directory_target}"
		$___file_output = "${___file_output}\${___directory_target}"
	}

	$___file_target = "$(FS-Extension-Remove "${___file_target}" "*")"
	if ("${___mode}" -eq "test") {
		$___file_log = "${___file_log}\${___file_target}_test.log"
	} else {
		$___file_log = "${___file_log}\${___file_target}_build.log"
	}
	$null = FS-Make-Housing-Directory "${___file_log}"

	$___file_output = "${___file_output}\${___file_target}"
	switch ("${___target_os}") {
	"windows" {
		$___file_output = "${___file_output}.exe"
	} default {
		$___file_output = "${___file_output}.elf"
	}}
	$null = FS-Make-Housing-Directory "${___file_output}"

	if ("${___mode}" -eq "test") {
		$null = I18N-Test "${___file_output}" *>> "${___file_log}"
		if ("${___target_os}" -ne "${env:PROJECT_OS}") {
			$null = I18N-Test-Skipped *>> "${___file_log}"
			return 10 # skipped - cannot operate in host environment
		}

		$($___process = FS-Is-File "${___file_output}") *> "${___file_log}"
		if ($___process -ne 0) {
			$null = I18N-Test-Failed *>> "${___file_log}"
			return 1 # failed - build stage
		}

		$___process = OS-Exec `
			"${___file_output}" `
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
	$___arguments = @"
${___arguments} --out:${___file_output} ${___directory_source}\${___target}
"@
	$___process = OS-Exec `
			"nim" `
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




function NIM-Run-Test {
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

	$___process = NIM-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\test-${env:PROJECT_NIM}"
	$___log = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\test-${env:PROJECT_NIM}"
	$___build_list = "${___workspace}\build-list.txt"
	$___test_list = "${___workspace}\test-list.txt"
	$null = FS-Remake-Directory "${___workspace}"
	$null = FS-Remake-Directory "${___log}"

	## (1) Scan for all test files
	foreach ($__line in (Get-ChildItem -Path "${___directory}" `
			-Recurse `
			-Filter "*_test.nim").FullName) {
		$___process = FS-Append-File "${___build_list}" @"
build|${___directory}|${___workspace}|${___log}|${__line}|${___os}|${___arch}|${___arguments}

"@
		if ($___process -ne 0) {
			return 1
		}

		$___process = FS-Append-File "${___test_list}" @"
test|${___directory}|${___workspace}|${___log}|${__line}|${___os}|${___arch}|${___arguments}

"@
		if ($___process -ne 0) {
			return 1
		}
	}

	## (2) Bail early if test is unavailable
	$___process = FS-Is-File "${___build_list}"
	if ($___process -ne 0) {
		return 0
	}

	$___process = FS-Is-File "${___test_list}"
	if ($___process -ne 0) {
		return 0
	}

	## (3) Build all test artifacts
	$___process = SYNC-Exec-Parallel `
		${function:NIM-Run-Parallel}.ToString() `
		"${___build_list}" `
		"${___workspace}"
	if ($___process -ne 0) {
		return 1
	}

	## (4) Execute all test artifacts
	$___process = SYNC-Exec-Parallel `
		${function:NIM-Run-Parallel}.ToString() `
		"${___test_list}" `
		"${___workspace}"
	if ($___process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function NIM-Setup {
	# validate input
	$___process = NIM-Is-Available
	if ($___process -eq 0) {
		return 0
	}

	$___process =  OS-Is-Command-Available "choco"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "choco" "install nim -y"
	if ($___process -ne 0) {
		return 1
	}
	$null = OS-Sync


	# report status
	return 0
}




function NIM-Setup-Local-Environment {
	# validate input
	$___process = NIM-Is-Localized
	if ($___process -eq 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_ROOT}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_TOOLS}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_NIM_ENGINE}") -eq 0) {
		return 1
	}

	$null = OS-Exec
	$___process = NIM-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___label = "($env:PROJECT_PATH_NIM_ENGINE)"
	$___location = "$(NIM-Get-Activator-Path)"

	$null = FS-Make-Housing-Directory "${___location}"
	$null = FS-Write-File "${___location}" @"
if (-not (Get-Command "nim" -ErrorAction SilentlyContinue)) {
	Write-Error "[ ERROR ] missing nim compiler."
	return
}

if (-not (Get-Command "nimble" -ErrorAction SilentlyContinue)) {
	Write-Error "[ ERROR ] missing nimble package manager."
	return
}

function deactivate {
	if ([string]::IsNullOrEmpty(`$env:old_NIMBLE_DIR)) {
		`${env:NIMBLE_DIR} = `$null
		`${env:old_NIMBLE_DIR} = `$null
	} else {
		`${env:NIMBLE_DIR} = "`${env:old_NIMBLE_DIR}"
		`${env:old_NIMBLE_DIR} = `$null
	}
	`${env:PROJECT_NIM_LOCALIZED} = `$null
	Copy-Item -Path Function:_OLD_PROMPT -Destination Function:prompt
	Remove-Item -Path Function:_OLD_PROMPT
}


# check existing
if (-not [string]::IsNullOrEmpty(`${env:PROJECT_NIM_LOCALIZED})) {
	return
}


# activate
`$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") ``
	+ ";" ``
	+ [System.Environment]::GetEnvironmentVariable("Path","User")
`${env:old_NIMBLE_DIR} = "`${NIMBLE_DIR}"
`${env:NIMBLE_DIR} = "$(FS-Get-Directory "${___location}")"
`${env:PROJECT_NIM_LOCALIZED} = "${___location}"
Copy-Item -Path function:prompt -Destination function:_OLD_PROMPT
function global:prompt {
	Write-Host -NoNewline -ForegroundColor Green "(${___label}) "
	_OLD_VIRTUAL_PROMPT
}
"@
	$___process = FS-Is-File "${___location}"
	if ($___process -ne 0) {
		return 1
	}


	# testing the activation
	$___process = NIM-Activate-Local-Environment
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
