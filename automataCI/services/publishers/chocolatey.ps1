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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\net\http.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\zip.ps1"




function CHOCOLATEY-Is-Available {
	# execute
	$__process = OS-Is-Command-Available "choco"
	if ($__process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function CHOCOLATEY-Is-Valid-Nupkg {
	param(
		[string]$__target
	)


	# validate input
	if ([string]::IsNullOrEmpty($__target) -or (-not (Test-Path -Path "${__target}"))) {
		return 1
	}

	if ($__target -like "*.asc") {
		return 1
	}


	# execute
	$__process = FS-Is-Target-A-Chocolatey "${__target}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Is-Target-A-Nupkg "${__target}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHOCOLATEY-Archive {
	param (
		[string]$__destination,
		[string]$__source
	)


	# validate input
	if ([string]::IsNullOrEmpty($__source) -or [string]::IsNullOrEmpty($__destination)) {
		return 1
	}


	# execute
	$__current_path = Get-Location
	$null = Set-Location -Path "${__source}"
	$__process = ZIP-Create "${__destination}" "*"
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHOCOLATEY-Publish {
	param (
		[string]$__target,
		[string]$__destination
	)


	# validate input
	if ([string]::IsNullOrEmpty($__target) -or [string]::IsNullOrEmpty($__destination)) {
		return 1
	}


	# execute
	$null = FS-Make-Directory "${__destination}"
	$__process = FS-Copy-File `
		"${__target}" `
		"${__destination}\$(Split-Path -Leaf -Path "${__target}")"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHOCOLATEY-Setup {
	# validate input
	$__process = OS-Is-Command-Available "choco"
	if ($__process -eq 0) {
		$null = choco upgrade chocolatey -y
		return 0
	}


	# execute
	$__process = HTTP-Download `
		"GET" `
		"https://community.chocolatey.org/install.ps1" `
		"install.ps1"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Is-File ".\install.ps1"
	if ($__process -ne 0) {
		return 1
	}

	$null = Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
	$__process = OS-Exec "powershell" ".\install.ps1"
	if ($__process -ne 0) {
		return 1
	}
	$null = FS-Remove-Silently ".\install.ps1"


	# return status
	return OS-Is-Command-Available "choco"
}




function CHOCOLATEY-Test {
	param(
		[string]$__target
	)


	# validate input
	if ([string]::IsNullOrEmpty($__target) -or (-not (Test-Path "${__target}"))) {
		return 1
	}

	$__process = CHOCOLATEY-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$__name = Split-Path -Leaf -Path "${__target}"
	$__name = $__name -replace '\-chocolatey.*$', ''


	## test install
	$__current_path = Get-Location
	$null = Set-Location "$(Split-Path -Parent -Path "${__target}")"
	$__arguments = "install ${__name} " `
			+ "--debug " `
			+ "--verbose " `
			+ "--force " `
			+ "--source `".`" "
	$__process = OS-Exec "choco" "${__arguments}"
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable "__current_path"
	if ($__process -ne 0) {
		return 1
	}


	## test uninstall
	$__current_path = Get-Location
	$null = Set-Location "$(Split-Path -Parent -Path "${__target}")"
	$__arguments = "uninstall ${__name} " `
			+ "--debug " `
			+ "--verbose " `
			+ "--force " `
			+ "--source `".`" "
	$__process = OS-Exec "choco" "${__arguments}"
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable "__current_path"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
