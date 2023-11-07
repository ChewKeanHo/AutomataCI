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
		[string]$__order
	)


	# validate input
	$__process = DOTNET-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# execute
	${env:DOTNET_CLI_TELEMETRY_OPTOUT} = 1
	${env:DOTNET_ROOT} = "$(DOTNET-Get-Path-Root)"

	$__arguments = "tool install --tool-path `"$(DOTNET-Get-Path-Bin)`" ${__order}"
	$__process = Start-Process -Wait -NoNewWindow -PassThru `
		-FilePath "$(DOTNET-Get-Path-Root)\dotnet.exe" `
		-ArgumentList "${__arguments}"
	if ($__process.ExitCode -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DOTNET-Is-Available {
	# execute
	if (-not (Test-Path -PathType Container -Path "$(DOTNET-Get-Path-Root)")) {
		return 1
	}

	if (Test-Path "$(DOTNET-Get-Path-Root)\dotnet.exe") {
		return 0
	}


	# report status
	return 1
}




function DOTNET-Setup {
	# validate input
	$__process = DOTNET-Is-Available
	if ($__process -eq 0) {
		return 0
	}


	# execute
	${env:DOTNET_CLI_TELEMETRY_OPTOUT} = 1
	$null = Invoke-Expression "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\dotnet-install.ps1 -Channel LTS -InstallDir `"$(DOTNET-Get-Path-Root)`""
	if (-not (Test-Path "$(DOTNET-Get-Path-Root)\dotnet.exe")) {
		return 1
	}


	# report status
	return 0
}
