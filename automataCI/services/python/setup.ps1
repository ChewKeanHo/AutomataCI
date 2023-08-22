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
function Setup-Python {
	[CmdletBinding()]
	Param (
	)
	$location = $env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_TOOLS + "\" `
			+ $env:PROJECT_PATH_PYTHON_ENGINE
	$activator = Join-Path $location "Scripts\Activate.ps1"
	$program = Get-Command python -ErrorAction SilentlyContinue

	# check if the repo is already established...
	if (Test-Path "$activator") {
		Write-Host "[ INFO ] $location is already established."
		return 0
	}

	# it's a clean repo. Start setting up virtual environment...
	$process = Start-Process -Wait `
				-FilePath "$program" `
				-NoNewWindow `
				-ArgumentList "-m venv `"$location`"" `
				-PassThru
	$process = $process.ExitCode
	if ($process -ne 0) {
		Write-Host "[ ERROR ] failed to setup virual environment at $location"
		return 1
	}

	# last check
	if (Test-Path "$activator") {
		Write-Host "[ INFO ] $location is now established."
		return 0
	}

	return 1
}
