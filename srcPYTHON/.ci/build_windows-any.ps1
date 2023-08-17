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




# (2) run build service
$program = Get-Command pyinstaller -ErrorAction SilentlyContinue
if (-not ($program)) {
	Write-Error "[  FAILED  ] missing pyinstaller."
	return 1
}


Write-Host "[  INFO  ] Building output..."
$argument = "--noconfirm " `
	+ "--onefile " `
	+ "--clean " `
	+ "--distpath `"" + $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_BUILD + "`" " `
	+ "--workpath `"" + $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_TEMP + "`" " `
	+ "--specpath `"" + $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_SOURCE + "`" " `
	+ "--name `"" + $env:PROJECT_SKU + "_" + $env:PROJECT_OS + "-" + $env:PROJECT_ARCH + "`" "`
	+ "--hidden-import=main " `
	+ "`"" + $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_SOURCE + "\main.py" + "`""

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
