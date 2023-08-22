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




# (0) initialize
IF (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
        Write-Error "[ ERROR ] - Please start from ci.cmd instead!\n"
        exit 1
}




# (1) execute tech-specific CI job
$recipe = $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_SOURCE + "\" + $env:PROJECT_PATH_CI
$recipe = "$recipe\setup_windows-any.ps1"
$process = Start-Process -Wait `
			-FilePath "powershell.exe" `
			-NoNewWindow `
			-ArgumentList "-File `"$recipe`"" `
			-PassThru
exit $process.ExitCode
