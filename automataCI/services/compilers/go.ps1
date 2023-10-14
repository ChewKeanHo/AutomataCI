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




function GO-Activate-Local-Environment {
	# validate input
	$__process = GO-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = GO-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__location = "$(GO-Get-Activator-Path)"
	if (-not (Test-Path "${__location}")) {
		return 1
	}

	. $__location
	$__process = GO-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function GO-Get-Activator-Path {
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}" `
		+ "\${env:PROJECT_PATH_GO_ENGINE}\Activate.ps1"
}




function GO-Is-Available {
	$__program = Get-Command go -ErrorAction SilentlyContinue
	if ($__program) {
		return 0
	}

	return 1
}




function GO-Is-Localized {
	if (-not [string]::IsNullOrEmpty($env:PROJECT_GO_LOCALIZED)) {
		return 0
	}

	return 1
}




function GO-Setup-Local-Environment {
	# validate input
	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_ROOT)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_TOOLS)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_GO_ENGINE)) {
		return 1
	}


	# execute
	$__process = GO-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__process = GO-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	## it's a clean repo. Start setting up localized environment...
	$__label = "($env:PROJECT_PATH_GO_ENGINE)"
	$__location = "$(GO-Get-Activator-Path)"

	$null = FS-Make-Housing-Directory "${__location}"
	$null = FS-Make-Directory "$(Split-Path -Path ${__location})\bin"
	$null = FS-Make-Directory "$(Split-Path -Path ${__location})\cache"
	$null = FS-Make-Directory "$(Split-Path -Path ${__location})\env"
	$null = FS-Write-File "${__location}" @"
if (-not (Get-Command "go" -ErrorAction SilentlyContinue)) {
	Write-Error "[ ERROR ] missing go compiler."
	return
}

function deactivate {
	`${env:GOPATH} = "$(Invoke-Expression "go env GOPATH")"
	`${env:GOBIN} = "$(Invoke-Expression "go env GOBIN")"
	`${env:GOCACHE} = "$(Invoke-Expression "go env GOCACHE")"
	`${env:GOENV} = "$(Invoke-Expression "go env GOENV")"
	`${env:PROJECT_GO_LOCALIZED} = `$null
	Copy-Item -Path Function:_OLD_PROMPT -Destination Function:prompt
	Remove-Item -Path Function:_OLD_PROMPT
}

# activate
`$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") ``
	+ ";" ``
	+ [System.Environment]::GetEnvironmentVariable("Path","User")
`${env:GOPATH} = "$(Split-Path -Path ${__location})"
`${env:GOBIN} = "$(Split-Path -Path ${__location})\bin"
`${env:GOCACHE} = "$(Split-Path -Path ${__location})\cache"
`${env:GOENV} = "$(Split-Path -Path ${__location})\env"
`${env:PROJECT_GO_LOCALIZED} = "${__location}"
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
	$__process = GO-Activate-Local-Environment
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
