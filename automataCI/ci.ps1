# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
if (-not (Test-Path -Path "${env:PROJECT_PATH_ROOT}")) {
	$null = Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}




# configure charset encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [console]::InputEncoding `
		= [console]::OutputEncoding `
		= New-Object System.Text.UTF8Encoding




# determine PROJECT_PATH_PWD
$env:PROJECT_PATH_PWD = Get-Location
$env:PROJECT_PATH_AUTOMATA = "automataCI"
$env:PROJECT_PATH_ROOT = ""




# determine PROJECT_PATH_ROOT
if (Test-Path ".\ci.ps1") {
	# currently inside the automataCI directory.
	${env:PROJECT_PATH_ROOT} = Split-Path -Parent "${env:PROJECT_PATH_PWD}"
} elseif (Test-Path ".\${env:PROJECT_PATH_AUTOMATA}\ci.ps1") {
	# current directory is the root directory.
	${env:PROJECT_PATH_ROOT} = "${env:PROJECT_PATH_PWD}"
} else {
	# scan from current directory - bottom to top
	$__pathing = "${env:PROJECT_PATH_PWD}"
	${env:PROJECT_PATH_ROOT} = ""
	foreach ($__pathing in (${env:PROJECT_PATH_PWD}.Split("\"))) {
		if (-not [string]::IsNullOrEmpty($env:PROJECT_PATH_ROOT)) {
			${env:PROJECT_PATH_ROOT} += "\"
		}
		${env:PROJECT_PATH_ROOT} += "${__pathing}"

		if (Test-Path -Path `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\ci.ps1") {
			break
		}
	}
	$null = Remove-Variable -Name __pathing

	if (-not (Test-Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\ci.ps1")) {
		Write-Error "[ ERROR ] Missing root directory.`n`n"
		exit 1
	}
}

${env:LIBS_AUTOMATACI} = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}"
${env:LIBS_HESTIA} = "${env:LIBS_AUTOMATACI}\services"




# import fundamental libraries
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# determine host system parameters
$env:PROJECT_OS = "$(OS-Get)"
if ($(STRINGS-Is-Empty "$env:PROJECT_OS") -eq 0) {
	$null = I18N-Unsupported-OS
	return 1
}

${env:PROJECT_ARCH} = "$(OS-Get-Arch)"
if($(STRINGS-Is-Empty "${env:PROJECT_ARCH}") -eq 0) {
	$null = I18N-Unsupported-ARCH
	return 1
}




# parse repo CI configurations
if (-not (Test-Path -Path "${env:PROJECT_PATH_ROOT}\CONFIG.toml")) {
	$null = I18N-Missing "CONFIG.toml"
	return 1
}


foreach ($__line in (Get-Content "${env:PROJECT_PATH_ROOT}\CONFIG.toml")) {
	$__line = $__line -replace '#.*', ''

	$__process = STRINGS-Is-Empty "${__line}"
	if ($__process -eq 0) {
		continue
	}

	$__key, $__value = $__line -split '=', 2
	$__key = $__key.Trim() -replace '^''|''$|^"|"$'
	$__value = $__value.Trim() -replace '^''|''$|^"|"$'

	$null = Set-Item -Path "env:$__key" -Value $__value
}




# parse repo CI secret configurations
if (Test-Path -Path "${env:PROJECT_PATH_ROOT}\SECRETS.toml" -PathType leaf) {
	foreach ($__line in (Get-Content "${env:PROJECT_PATH_ROOT}\SECRETS.toml")) {
		$__line = $__line -replace '#.*', ''
		$__process = STRINGS-Is-Empty "${__line}"
		if ($__process -eq 0) {
			continue
		}

		$__key, $__value = $__line -split '=', 2
		$__key = $__key.Trim() -replace '^''|''$|^"|"$'
		$__value = $__value.Trim() -replace '^''|''$|^"|"$'

		$null = Set-Item -Path "env:$__key" -Value $__value
	}
}




# determine language
if ($(STRINGS-Is-Empty "${env:AUTOMATACI_LANG}") -eq 0) {
	$env:AUTOMATACI_LANG = "$(OS-Get-Lang)"
	if ($(STRINGS-Is-Empty "${env:AUTOMATACI_LANG}") -eq 0) {
		$env:AUTOMATACI_LANG = "en" # fallback to english
	}
}




# update environment variables
$null = OS-Sync




# execute command
switch ($args[0]) {
{ $_ -in 'env', 'Env', 'ENV' } {
	$env:PROJECT_CI_JOB = "env"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\env_windows-any.ps1"
} { $_ -in 'setup', 'Setup', 'SETUP' } {
	$env:PROJECT_CI_JOB = "setup"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'start', 'Start', 'START' } {
	$env:PROJECT_CI_JOB = "start"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'test', 'Test', 'TEST' } {
	$env:PROJECT_CI_JOB = "test"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'prepare', 'Prepare', 'PREPARE' } {
	$env:PROJECT_CI_JOB = "prepare"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'materialize', 'Materialize', 'MATERIALIZE' } {
	$env:PROJECT_CI_JOB = "materialize"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'build', 'Build', 'BUILD' } {
	$env:PROJECT_CI_JOB = "build"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'notarize', 'Notarize', 'NOTARIZE' } {
	$env:PROJECT_CI_JOB = "notarize"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\notarize_windows-any.ps1"
} { $_ -in 'package', 'Package', 'PACKAGE' } {
	$env:PROJECT_CI_JOB = "package"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\package_windows-any.ps1"
} { $_ -in 'release', 'Release', 'RELEASE' } {
	$env:PROJECT_CI_JOB = "release"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\release_windows-any.ps1"
} { $_ -in 'stop', 'Stop', 'STOP' } {
	$env:PROJECT_CI_JOB = "stop"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'deploy', 'Deploy', 'DEPLOY' } {
	$env:PROJECT_CI_JOB = "deploy"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'archive', 'Archive', 'ARCHIVE' } {
	$env:PROJECT_CI_JOB = "archive"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\archive_windows-any.ps1"
} { $_ -in 'clean', 'Clean', 'CLEAN' } {
	$env:PROJECT_CI_JOB = "clean"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\common_windows-any.ps1"
} { $_ -in 'purge', 'Purge', 'PURGE' } {
	$env:PROJECT_CI_JOB = "purge"
	$__exit_code = . "${env:LIBS_AUTOMATACI}\purge_windows-any.ps1"
} default {
	switch ($args[0]) {
	{ $_ -in '-h', '--help', 'help', '--Help', 'Help', '--HELP', 'HELP' } {
		$null = I18N-Help info
		$__exit_code = 0
	} default {
		$null = I18N-Unknown-Action
		$null = I18N-Help note
		$__exit_code = 1
	}}
}}
return $__exit_code
