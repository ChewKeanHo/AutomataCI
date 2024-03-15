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
		Write-Host "DEBUG: nim root path failed"
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_TOOLS}") -eq 0) {
		Write-Host "DEBUG: nim tool path failed"
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_NIM_ENGINE}") -eq 0) {
		Write-Host "DEBUG: nim engine path failed"
		return 1
	}

	$null = OS-Exec
	$___process = NIM-Is-Available
	if ($___process -ne 0) {
		Write-Host "DEBUG: nim available failed"
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
