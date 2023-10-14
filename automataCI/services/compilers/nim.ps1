# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"




function NIM-Activate-Local-Environment {
	# validate input
	$__process = NIM-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = NIM-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__location = "$(NIM-Get-Activator-Path)"
	if (-not (Test-Path "${__location}")) {
		return 1
	}

	. $__location
	$__process = NIM-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function NIM-Check-Package {
	param(
		[string]$__directory
	)


	# execute
	$__current_path = Get-Location
	$null = Set-Location "${__directory}"
	$__process = OS-Exec "nimble" "check"
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable __current_path
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NIM-Get-Activator-Path {
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}" `
		+ "\${env:PROJECT_PATH_NIM_ENGINE}\Activate.ps1"
}




function NIM-Is-Available {
	# execute
	$__program = Get-Command nim -ErrorAction SilentlyContinue
	if (-not $__program) {
		return 1
	}

	$__program = Get-Command nimble -ErrorAction SilentlyContinue
	if (-not $__program) {
		return 1
	}

	$__program = Get-Command gcc -ErrorAction SilentlyContinue
	if ($__program) {
		return 0
	}

	$__program = Get-Command x86_64-w64-mingw32-gcc -ErrorAction SilentlyContinue
	if ($__program) {
		return 0
	}


	# report status
	return 1
}




function NIM-Is-Localized {
	# execute
	if (-not [string]::IsNullOrEmpty($env:PROJECT_NIM_LOCALIZED)) {
		return 0
	}


	# report status
	return 1
}




function NIM-Setup-Local-Environment {
	# validate input
	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_ROOT)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_TOOLS)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_NIM_ENGINE)) {
		return 1
	}


	# execute
	$__process = NIM-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = NIM-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	## it's a clean repo. Start setting up localized environment...
	$__label = "($env:PROJECT_PATH_NIM_ENGINE)"
	$__location = "$(NIM-Get-Activator-Path)"

	$null = FS-Make-Housing-Directory "${__location}"
	$null = FS-Write-File "${__location}" @"
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

# activate
`$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") ``
	+ ";" ``
	+ [System.Environment]::GetEnvironmentVariable("Path","User")
`${env:old_NIMBLE_DIR} = "`${NIMBLE_DIR}"
`${env:NIMBLE_DIR} = "$(Split-Path -Parent -Path "${__location}")"
`${env:PROJECT_NIM_LOCALIZED} = "${__location}"
Copy-Item -Path function:prompt -Destination function:_OLD_PROMPT
function global:prompt {
	Write-Host -NoNewline -ForegroundColor Green "(${__label}) "
	_OLD_VIRTUAL_PROMPT
}
"@

	if (-not (Test-Path "${__location}")) {
		return 1
	}


	# testing the activation
	$__process = NIM-Activate-Local-Environment
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
