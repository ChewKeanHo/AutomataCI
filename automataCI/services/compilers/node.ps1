# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\net\http.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"




function NODE-Activate-Local-Environment {
	# validate input
	$___process = NODE-Is-Localized
	if ($___process -eq 0) {
		$___process = NODE-Is-Available
		if ($___process -ne 0) {
			return 1
		}

		return 0
	}


	# execute
	$___location = "$(NODE-Get-Activator-Path)"
	$___process = FS-Is-File "${___location}"
	if ($___process -ne 0) {
		return 1
	}

	. "${___location}"
	$___process = NODE-Is-Localized
	if ($___process -ne 0) {
		return 1
	}

	$___process = NODE-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NODE-Get-Activator-Path {
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${env:PROJECT_PATH_NODE_ENGINE}\Activate.ps1"
}




function NODE-Is-Available {
	# execute
	if ($(STRINGS-Is-Empty "${env:PROJECT_NODE_VERSION}") -ne 0) {
		## check existing localized engine
		$___target = "$(NODE-Get-Activator-Path)"
		$___process = FS-Is-File "${___target}"
		if ($___process -ne 0) {
			return 1
		}
		$___target = "$(FS-Get-Directory "${___target}")"

		## check localized node command availability
		$___process = FS-Is-File "${___target}\node.exe"
		if ($___process -ne 0) {
			return 1
		}

		## check localized npm command availability
		$___process = FS-Is-File "${___target}\npm"
		if ($___process -ne 0) {
			return 1
		}

		## check localized npm command availability
		$___process = FS-Is-File "${___target}\npx"
		if ($___process -ne 0) {
			return 1
		}

		return 0
	}

	$___process = OS-Is-Command-Available "npm"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "npx"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "node"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 1
}




function NODE-Is-Localized {
	# execute
	if ($(STRINGS-Is-Empty "${env:PROJECT_NODE_LOCALIZED}") -ne 0) {
		return 0
	}


	# report status
	return 1
}




function NODE-NPM-Check-Login {
	# execute
	if ($(STRINGS-Is-Empty "${env:PROJECT_NODE_NPM_REGISTRY}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:NPM_USERNAME}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:NPM_TOKEN}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_SCOPE}") -eq 0) {
		return 1
	}


	# report status
	return 0
}




function NODE-NPM-Install-Dependencies-All {
	# validate input
	$___process = NODE-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "npm" "install"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NODE-NPM-Is-Valid {
	param(
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "$1"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = FS-Is-Target-A-NPM "$1"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NODE-NPM-Publish {
	param(
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "$1") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = NODE-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\release-npm"
	$___package = "${env:PROJECT_SKU}.tgz"
	$___npmrc = ".npmrc"

	## setup workspace
	$null = FS-Remake-Directory "${___workspace}"
	$___process = FS-Copy-File "${___target}" "${___workspace}\${___package}"
	if ($___process -ne 0) {
		return 1
	}

	$___current_path = Get-Location
	$null = Set-Location "${___workspace}"
	$___process = FS-Write-File "${___npmrc}" @"
registry=${env:PROJECT_NODE_NPM_REGISTRY}
scope=@${env:PROJECT_SCOPE}
email=$env:NPM_USERNAME
//${PROJECT_NODE_NPM_REGISTRY#*://}/:_authToken=${env:NPM_TOKEN}
"@
	if ($___process -ne 0) {
		$null = FS-Remove-Silently "${___npmrc}"
		return 1
	}

	$___process = FS-Is-File "${___npmrc}"
	if ($___process -ne 0) {
		return 1
	}

	## publish
	$___process = OS-Exec "npm" "publish `"${___package}`""
	$null = FS-Remove-Silently "${___npmrc}"
	$null = Set-Location "${___current_path}"
	$null = Remove-Variable ___current_path
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NODE-NPM-Run {
	param(
		[string]$___name
	)


	# validate input
	$___process = NODE-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${___name}") -eq 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "npm" "run `"${___name}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function NODE-Setup {
	# validate input
	$___process = NODE-Is-Available
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___filepath = ""
	switch ("${env:PROJECT_ARCH}") {
	"amd64" {
		$___filepath = "x64"
	} "arm" {
		$___filepath = "armv7l"
	} "arm64" {
		$___filepath = "arm64"
	} "ppc64le" {
		$___filepath = "ppc64le"
	} "s390x" {
		$___filepath = "s390x"
	} default {
		return 1
	}}

	switch ("${env:PROJECT_OS}") {
	"aix" {
		$___filepath = "aix-${___filepath}.tar.xz"
	} "darwin" {
		$___filepath = "darwin-${___filepath}.tar.xz"
	} "windows" {
		$___filepath = "win-${___filepath}.zip"
	} "linux" {
		$___filepath = "linux-${___filepath}.tar.xz"
	} default {
		return 1
	}}

	## download engine
	$___filepath = "node-${env:PROJECT_NODE_VERSION}-${___filepath}"
	$___url = "https://nodejs.org/dist/${env:PROJECT_NODE_VERSION}/${___filepath}"
	$___filepath = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${___filepath}"

	$null = FS-Make-Housing-Directory "${___filepath}"
	$null = FS-Remove-Silently "${___filepath}"
	$___process = HTTP-Download "GET" "${___url}" "${___filepath}"
	if ($___process -ne 0) {
		return 1
	}

	## unpack engine
	$___process = FS-Is-File "${___filepath}"
	if ($___process -ne 0) {
		return 1
	}

	$___location = "$(NODE-Get-Activator-Path)"
	$___directory = "$(FS-Get-Directory "${___location}")"
	$null = FS-Remove-Silently "${___directory}"

	$___target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\"
	$null = FS-Make-Directory "${___target}"
	switch ("${env:PROJECT_OS}") {
	"windows" {
		$___process = ZIP-Extract "${___target}" "${___filepath}"
		$null = FS-Remove-Silently "${___filepath}"
		$___target = FS-Extension-Replace "${___filepath}" ".zip" ""
	} default {
		$___process = TAR-Extract-XZ "${___target}" "${___filepath}"
		$null = FS-Remove-Silently "${___filepath}"
		$___target = FS-Extension-Replace "${___filepath}" ".tar.xz" ""
	}}
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Move "${___target}" "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	## create activator script
	$___label = "(${env:PROJECT_PATH_NODE_ENGINE})"
	$___target = "${___directory}"
	$null = FS-Write-File "${___location}" @"
`$___target = `"${___target}`"


function deactivate {
	`$env:Path = (`$env:Path.Split(';') | Where-Object { `$_ -ne "`${___target}" }) -join ';'

	`${env:PROJECT_NODE_LOCALIZED} = `$null
	Copy-Item -Path Function:_OLD_PROMPT -Destination Function:prompt
	Remove-Item -Path Function:_OLD_PROMPT
}


# check existing
if (-not [string]::IsNullOrEmpty(`${env:PROJECT_NODE_LOCALIZED})) {
	return
}


# activate
`$env:Path = `$env:Path + ";" + "`${___target}"

`${env:PROJECT_NODE_LOCALIZED} = "${___location}"
`$null = Copy-Item -Path function:prompt -Destination function:_OLD_PROMPT
function global:prompt {
	Write-Host -NoNewline -ForegroundColor Green "(${___label}) "
	_OLD_VIRTUAL_PROMPT
}
"@
	$___process = FS-Is-File "${___location}"
	if ($___process -ne 0) {
		return 1
	}

	## test activator script
	$___process = NODE-Activate-Local-Environment
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
