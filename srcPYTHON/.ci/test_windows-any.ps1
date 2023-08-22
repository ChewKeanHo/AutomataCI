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
		+ "services\io\os.ps1"
. $services

$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\io\fs.ps1"
. $services

$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\compilers\python.ps1"
. $services


OS-Print-Status info "checking python availability..."
$process = PYTHON-Is-Available
if ($process -ne 0) {
	OS-Print-Status error "missing python intepreter."
	exit 1
}

OS-Print-Status info "activating python venv..."
$process = PYTHON-Activate-VENV
if ($process -ne 0) {
	OS-Print-Status error "activation failed."
	exit 1
}




# (2) run test service
$report_location = $env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_LOG + "\" `
			+ "python-test-report"
OS-Print-Status info "preparing report value: $report_location"
$process = FS-Make-Directory $report_location
if ($process -ne 0) {
	OS-Print-Status error "preparation failed."
	exit 1
}


# (2.1) execute test run
OS-Print-Status info "executing all tests with coverage..."
$argument = "-m coverage run " `
	+ "--data-file=`"" + $report_location + "\.coverage" + "`" " `
	+ "-m unittest discover " `
	+ "-s `"" + $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_SOURCE + "`" " `
	+ "-p '*_test.py'"
$process = OS-Exec python $argument
if ($process -ne 0) {
	OS-Print-Status error "test executions failed."
	exit 1
}


# (2.2) process test report
OS-Print-Status info "processing test coverage data to html..."
$argument = "-m coverage html " `
	+ "--data-file=`"" + $report_location + "\.coverage" + "`" " `
	+ "--directory=`"" + $report_location + "`""
$process = OS-Exec python $argument
if ($process -ne 0) {
	OS-Print-Status error "data processing failed."
	exit 1
}




# (3) report successful status
OS-Print-Status success ""
exit 0
