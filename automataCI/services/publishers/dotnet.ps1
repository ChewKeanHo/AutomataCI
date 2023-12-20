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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\net\http.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"




function DOTNET-Add {
	param(
		[string]$___order,
		[string]$___version,
		[string]$___destination,
		[string]$___extractions
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___order}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${___version}") -eq 0) {
		$___version = "latest"
	}
	$___version = STRINGS-To-Lowercase "${___version}"


	# execute
	## configure settings
	$___pkg = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${env:PROJECT_PATH_NUPKG}"
	$___pkg = "${___pkg}\${___order}_${___version}"
	if ($___version -eq "latest") {
		$null = FS-Remove-Silently "${___pkg}"
	}

	## begin sourcing nupkg
	$___process = FS-Is-File "${___pkg}/nupkg.zip"
	if ($___process -ne 0) {
		$___order = "https://www.nuget.org/api/v2/package/${___order}"
		if ($___version -ne "latest") {
			$___order = "${___order}/${___version}"
		}

		$null = FS-Make-Directory "${___pkg}"
		$___process = HTTP-Download "GET" "${___order}" "${___pkg}\nupkg.zip"
		if ($___process -ne 0) {
			FS-Remove-Silently "${___pkg}"
			return 1
		}

		$___process = FS-Is-File "${___pkg}/nupkg.zip"
		if ($___process -ne 0) {
			FS-Remove-Silently "${___pkg}"
			return 1
		}

		$___process = ZIP-Extract "${___pkg}" "${___pkg}/nupkg.zip"
		if ($___process -ne 0) {
			FS-Remove-Silently "${___pkg}"
			return 1
		}
	}


	## begin extraction
	if ($(STRINGS-Is-Empty "${___extractions}") -eq 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${___destination}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___destination}"
	if ($___process -eq 0) {
		return 1
	}
	$null = FS-Make-Directory "${___destination}"

	foreach ($___target in ($___extractions -split "\|")) {
		$___src = "${___pkg}\${___target}"
		$___dest = "${___destination}\$(Split-Path -Leaf -Path "${___target}")"

		$___process = FS-Is-File "${___src}"
		if ($___process -ne 0) {
			return 1
		}

		$null = FS-Remove-Silently "${___dest}"
		$___process = FS-Copy-File "${___src}" "${___dest}"
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}




function DOTNET-Activate-Environment {
	# validate input
	$___process = DOTNET-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = DOTNET-Is-Activated
	if ($___process -eq 0) {
		return 0
	}


	# execute
	${env:DOTNET_ROOT} = "$(DOTNET-Get-Path-Root)"
	${env:PATH} += ";${env:DOTNET_ROOT};${env:DOTNET_ROOT}\bin"


	# report
	$___process = DOTNET-Is-Activated
	if ($___process -ne 0) {
		return 1
	}

	return 0
}




function DOTNET-Get-Path-Bin {
	# report status
	return "$(DOTNET-Get-Path-Root)\bin"
}




function DOTNET-Get-Path-Root {
	# report status
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}\${env:PROJECT_PATH_DOTNET_ENGINE}"
}




function DOTNET-Install {
	param(
		[string]$___order
	)


	# validate input
	$___process = DOTNET-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$null = DOTNET-Activate-Environment
	$___process = DOTNET-Is-Activated
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___arguments = "tool install --tool-path `"$(DOTNET-Get-Path-Bin)`" ${___order}"
	$___process = Start-Process -Wait -NoNewWindow -PassThru `
		-FilePath "$(DOTNET-Get-Path-Root)\dotnet.exe" `
		-ArgumentList "${___arguments}"
	if ($___process.ExitCode -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DOTNET-Is-Activated {
	# execute
	if ($(STRINGS-Is-Empty "${env:DOTNET_ROOT}") -eq 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "dotnet"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DOTNET-Is-Available {
	# execute
	$___process = FS-Is-Directory "$(DOTNET-Get-Path-Root)"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "$(DOTNET-Get-Path-Root)\dotnet.exe"
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function DOTNET-Setup {
	# validate input
	$___process = DOTNET-Is-Available
	if ($___process -eq 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_DOTNET_CHANNEL}") -eq 0) {
		return 1
	}


	# execute
	$___arguments = "-ExecutionPolicy RemoteSigned " `
		+ "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\dotnet-install.ps1 " `
		+ "-Channel ${env:PROJECT_DOTNET_CHANNEL} " `
		+ "-InstallDir `"$(DOTNET-Get-Path-Root)`""
	$___process = OS-Exec "powershell" "${___arguments}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "$(DOTNET-Get-Path-Root)\dotnet.exe"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
