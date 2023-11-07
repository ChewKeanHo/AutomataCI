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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\dotnet.ps1"




function MSI-Is-Available {
	# execute
	$__process = DOTNET-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	if (-not (Test-Path "$(DOTNET-Get-Path-Bin)\wix.exe")) {
		return 1
	}

	${env:DOTNET_CLI_TELEMETRY_OPTOUT} = 1
	${env:DOTNET_ROOT} = "$(DOTNET-Get-Path-Root)"
	Start-Process -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue `
		-FilePath "$(DOTNET-Get-Path-Bin)\wix.exe" `
		-ArgumentList "--version *>$null" `
		-OutVariable __process *>$null
	if ((-not $__process) -or ($__process.ExitCode -gt 0)) {
		return 1
	}


	# report status
	return 0
}




function MSI-Setup {
	# validate input
	$__process = DOTNET-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$__process = DOTNET-Install "wix"
	if ($__process -ne 0) {
		return 1
	}

	$__process = MSI-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
