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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




# execute
OS-Print-Status info "executing test..."
$__current_path = Get-Location
if ($(OS-Is-Run-Simulated) -eq 0) {
	OS-Print-Status warning "simulating release repo conclusion..."
	$__exit_code = 0
} else {
	$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_ANGULAR}"
	$env:CHROME_BIN = Get-Command "chrome.exe" -ErrorAction SilentlyContinue
	if ($env:CHROME_BIN) {
		$env:CHROME_BIN = $env:CHROME_BIN.Source
	}
	$__exit_code = OS-Exec "ng" "test --no-watch --code-coverage"
}
$null = Set-Location "${__current_path}"
$null = Remove-Variable __current_path




# export report
OS-Print-Status info "exporting coverage report..."
$__process = FS-Is-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_ANGULAR}\coverage"
if ($__process -eq 0) {
	$log_path = "${env:PROJECT_PATH_ROOT}/${env:PROJECT_PATH_LOG}/angular-test-report"
	$null = FS-Remove-Silently "$log_path"
	$null = FS-Make-Housing-Directory "$log_path"
	$null = FS-Move "${env:PROJECT_PATH_ROOT}\${env:PROJECT_ANGULAR}\coverage" "$log_path"
}




# report status
if ($__exit_code -ne 0) {
	OS-Print-Status error "test failed."
	return 1
}

return 0
