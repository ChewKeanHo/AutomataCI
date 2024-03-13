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




function GO-Activate-Local-Environment {
	# validate input
	$___process = GO-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = GO-Is-Localized
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___location = "$(GO-Get-Activator-Path)"
	if ($(FS-Is-File "${___location}") -ne 0) {
		return 1
	}

	. "${___location}"
	$___process = GO-Is-Localized
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function GO-Get-Activator-Path {
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${env:PROJECT_PATH_GO_ENGINE}\Activate.ps1"
}




function GO-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "go"
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function GO-Is-Localized {
	# execute
	if ($(STRINGS-Is-Empty "${env:PROJECT_GO_LOCALIZED}") -ne 0) {
		return 0
	}


	# report status
	return 1
}




function GO-Setup {
	# validate input
	$___process = Go-Is-Available
	if ($___process -eq 0) {
		return 0
	}

	$___process = OS-Is-Command-Available "choco"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "choco" "install go -y"
	if ($___process -ne 0) {
		return 1
	}
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")


	# report status
	return 0
}




function GO-Setup-Local-Environment {
	# validate input
	$___process = GO-Is-Localized
	if ($___process -eq 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_ROOT}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_TOOLS}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_GO_ENGINE}") -eq 0) {
		return 1
	}

	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")
	$___process = GO-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___label = "($env:PROJECT_PATH_GO_ENGINE)"
	$___location = "$(GO-Get-Activator-Path)"

	$null = FS-Make-Housing-Directory "${___location}"
	$null = FS-Make-Directory "$(Split-Path -Path ${___location})\bin"
	$null = FS-Make-Directory "$(Split-Path -Path ${___location})\cache"
	$null = FS-Make-Directory "$(Split-Path -Path ${___location})\env"
	$null = FS-Write-File "${___location}" @"
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
`${env:GOPATH} = "$(Split-Path -Path ${___location})"
`${env:GOBIN} = "$(Split-Path -Path ${___location})\bin"
`${env:GOCACHE} = "$(Split-Path -Path ${___location})\cache"
`${env:GOENV} = "$(Split-Path -Path ${___location})\env"
`${env:PROJECT_GO_LOCALIZED} = "${___location}"
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
	$___process = GO-Activate-Local-Environment
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
