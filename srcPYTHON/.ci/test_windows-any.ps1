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




# (1) safety checking control surfaces
$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\python\common.ps1"
. $services


$process = Check-Python-Available
if ($process -ne 0) {
	exit 1
}


$process = Activate-Virtual-Environment
if ($process -ne 0) {
	exit 1
}




# (2) run test service
$report_location = $env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_TEMP + "\" `
			+ "python-test-report"


# (2.1) execute test run
Write-Host "[  INFO  ] Being test service..."
$program = Get-Command python -ErrorAction SilentlyContinue
$argument = "-m coverage run " `
	+ "--data-file=`"" + $report_location + "\.coverage" + "`" " `
	+ "-m unittest discover " `
	+ "-s `"" + $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_SOURCE + "`" " `
	+ "-p '*_test.py'"

$process = Start-Process -Wait `
			-FilePath "$program" `
			-NoNewWindow `
			-ArgumentList "$argument" `
			-PassThru
if ($process.ExitCode -ne 0) {
	Write-Error "[  FAILED  ]"
	exit 1
}

Write-Host "[ SUCCESS ]"


# (2.2) process test report
Write-Host "[  INFO  ] Processing test report..."

$report_location = $env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_TEMP + "\" `
			+ "python-test-report"
$program = Get-Command python -ErrorAction SilentlyContinue
$argument = "-m coverage html " `
	+ "--data-file=`"" + $report_location + "\.coverage" + "`" " `
	+ "--directory=`"" + $report_location + "`""

$process = Start-Process -Wait `
			-FilePath "$program" `
			-NoNewWindow `
			-ArgumentList "$argument" `
			-PassThru
if ($process.ExitCode -ne 0) {
	Write-Error "[  FAILED  ]"
	exit 1
}

Write-Host "[ SUCCESS ]"


exit 0
