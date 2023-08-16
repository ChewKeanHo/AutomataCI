# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.




# (0) initialize
IF (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
        Write-Error "[ ERROR ] - Please source from ci.cmd instead!\n"
        exit 1
}




# (1) run start service
$services = $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_AUTOMATA + "\services"




# (2) python is setup properly
. ("$services" + "\python\common.ps1")
$process = Check-Python-Available
if ($process -ne 0) {
	exit 1
}


$process = Activate-Virtual-Environment
if ($process -ne 0) {
	exit 1
}


$process = Check-Python-PIP
if ($process -ne 0) {
	exit 1
}




# (3) start prepare the service
Write-Host "[  INFO  ] Upgrading pip to the latest..."
$program = Get-Command python -ErrorAction SilentlyContinue
$process = Start-Process -Wait `
			-FilePath "$program" `
			-NoNewWindow `
			-ArgumentList "-m pip install --upgrade pip" `
			-PassThru
if ($process.ExitCode -ne 0) {
	Write-Error "[  FAILED  ]"
	exit 1
}
Write-Host "[ SUCCESS ]"


Write-Host "[  INFO  ] pip install all required modules..."
$program = Get-Command pip -ErrorAction SilentlyContinue
$location = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_SOURCE + "\" `
		+ "requirements.txt"
$process = Start-Process -Wait `
			-FilePath "$program" `
			-NoNewWindow `
			-ArgumentList "install -r $location" `
			-PassThru
if ($process.ExitCode -ne 0) {
	Write-Error "[  FAILED  ]"
	exit 1
}
Write-Host "[ SUCCESS ]"


exit 0
