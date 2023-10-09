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




function PACKAGE-Assemble-FLATPAK-Content {
	param(
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate target before job
	switch ($_target_arch) {
	{ $_ -in "avr" } {
		return 10 # not applicable
	} default {
		# accepted
	}}

	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Chocolatey "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($_target_os -ne "linux") {
		return 10 # not applicable
	}


	# copy main program
	$_filepath = "${_directory}\${env:PROJECT_SKU}"
	OS-Print-Status info "copying ${_target} to ${_filepath}"
	$__process = FS-Copy-File "${_target}" "${_filepath}"
	if ($__process -ne 0) {
		return 1
	}


	# copy icon.svg
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	$_target = "${_target}\icons\icon.svg"
	$_filepath = "${_directory}\icon.svg"
	OS-Print-Status info "copying ${_target} to ${_filepath}"
	$__process = FS-Copy-File "${_target}" "${_filepath}"
	if ($__process -ne 0) {
		return 1
	}


	# copy icon-48x48.png
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	$_target = "${_target}\icons\icon-128x128.png"
	$_filepath = "${_directory}\icon-48x48.png"
	OS-Print-Status info "copying ${_target} to ${_filepath}"
	$__process = FS-Copy-File "${_target}" "${_filepath}"
	if ($__process -ne 0) {
		return 1
	}


	# copy icon-128x128.png
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}"
	$_target = "${_target}\icons\icon-128x128.png"
	$_filepath = "${_directory}\icon-48x48.png"
	OS-Print-Status info "copying ${_target} to ${_filepath}"
	$__process = FS-Copy-File "${_target}" "${_filepath}"
	if ($__process -ne 0) {
		return 1
	}


	# OPTIONAL (overrides): copy manifest.yml or manifest.json
	# OPTIONAL (overrides): copy appdata.xml


	# report status
	return 0
}
