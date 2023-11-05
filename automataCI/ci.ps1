# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# make sure is by run initialization
if ($myinvocation.line.StartsWith(". ")) {
	Write-Error "[ ERROR ] - Run me instead -> $ ./ci.cmd [JOB]\n"
	exit 1
}




# scan for PROJECT_PATH_ROOT
$__pathing = "${env:PROJECT_PATH_PWD}"
$__previous = ""

while (-not ([string]::IsNullOrEmpty($__pathing))) {
	$env:PORJECT_PATH_ROOT += ($__pathing -split "/", 2)[0] + "/"
	$__pathing = ($__pathing -split "/", 2)[1]

	if (Test-Path -Path "${env:PROJECT_PATH_ROOT}automataCI/ci.ps1") {
		break
	}

	if ($__previous -eq $__pathing) {
		Write-Host "[ ERROR ] unable to detect repo root directory from PWD."
		exit 1
	}

	$__previous = $__pathing
}
Remove-Variable -Name __pathing
Remove-Variable -Name __previous
$env:PROJECT_PATH_ROOT = $env:PROJECT_PATH_ROOT.TrimEnd('\')
$env:PROJECT_PATH_AUTOMATA = "automataCI"




# detects initializer
if (-not (Test-Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\init.ps1")) {
	Write-Host "[ ERROR ] unable to find initializer service script."
	exit 1
}
$__process = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\init.ps1"
if ($__process -ne 0) {
	Write-Host "[ ERROR ] initialization failed.\n"
	exit 1
}




# execute command
switch ($args[0]) {
{ $_ -in 'env', 'Env', 'ENV' } {
	$env:PROJECT_CI_JOB = "env"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\env_windows-any.ps1"
} { $_ -in 'setup', 'Setup', 'SETUP' } {
	$env:PROJECT_CI_JOB = "setup"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'start', 'Start', 'START' } {
	$env:PROJECT_CI_JOB = "start"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'test', 'Test', 'TEST' } {
	$env:PROJECT_CI_JOB = "test"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'prepare', 'Prepare', 'PREPARE' } {
	$env:PROJECT_CI_JOB = "prepare"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'materialize', 'Materialize', 'MATERIALIZE' } {
	$env:PROJECT_CI_JOB = "materialize"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'build', 'Build', 'BUILD' } {
	$env:PROJECT_CI_JOB = "build"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'notarize', 'Notarize', 'NOTARIZE' } {
	$env:PROJECT_CI_JOB = "notarize"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\notarize_windows-any.ps1"
} { $_ -in 'package', 'Package', 'PACKAGE' } {
	$env:PROJECT_CI_JOB = "package"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\package_windows-any.ps1"
} { $_ -in 'release', 'Release', 'RELEASE' } {
	$env:PROJECT_CI_JOB = "release"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\release_windows-any.ps1"
} { $_ -in 'stop', 'Stop', 'STOP' } {
	$env:PROJECT_CI_JOB = "stop"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'deploy', 'Deploy', 'DEPLOY' } {
	$env:PROJECT_CI_JOB = "deploy"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'clean', 'Clean', 'CLEAN' } {
	$env:PROJECT_CI_JOB = "clean"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\common_windows-any.ps1"
} { $_ -in 'purge', 'Purge', 'PURGE' } {
	$env:PROJECT_CI_JOB = "purge"
	$__exit = . "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\purge_windows-any.ps1"
} Default {
	switch ($args[0]) {
	{ $_ -in '-h', '--help', 'help', '--Help', 'Help', '--HELP', 'HELP' } {
		$__exit = 0
	} Default {
		Write-Host "[ ERROR ] unknown action."
		$__exit = 1
	}}

	Write-Host "`nPlease try any of the following:"
	Write-Host "        To seek commands' help 🠚        $ ./ci.cmd help"
	Write-Host "        To initialize environment 🠚     $ ./ci.cmd env"
	Write-Host "        To setup the repo for work 🠚    $ ./ci.cmd setup"
	Write-Host "        To prepare the repo 🠚           $ ./ci.cmd prepare"
	Write-Host "        To start a development 🠚        $ ./ci.cmd start"
	Write-Host "        To test the repo 🠚              $ ./ci.cmd test"
	Write-Host "        Like build but only for host 🠚  $ ./ci.cmd materialize"
	Write-Host "        To build the repo 🠚             $ ./ci.cmd build"
	Write-Host "        To notarize the builds 🠚        $ ./ci.cmd notarize"
	Write-Host "        To package the repo product 🠚   $ ./ci.cmd package"
	Write-Host "        To release the repo product 🠚   $ ./ci.cmd release"
	Write-Host "        To stop a development 🠚         $ ./ci.cmd stop"
	Write-Host "        To deploy the new release 🠚     $ ./ci.cmd deploy"
	Write-Host "        To clean the workspace 🠚        $ ./ci.cmd clean"
	Write-Host "        To purge everything 🠚           $ ./ci.cmd purge"
}}
exit $__exit
