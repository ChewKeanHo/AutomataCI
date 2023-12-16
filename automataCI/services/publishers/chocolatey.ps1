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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\net\http.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"




function CHOCOLATEY-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "choco"
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function CHOCOLATEY-Is-Valid-Nupkg {
	param(
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File
	if ($___process -ne 0) {
		return 1
	}

	if ($___target -like "*.asc") {
		return 1
	}


	# execute
	$___process = FS-Is-Target-A-Chocolatey "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Target-A-Nupkg "${___target}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHOCOLATEY-Archive {
	param (
		[string]$___destination,
		[string]$___source
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___source}") -eq 0) -or
		($(STRINGS-Is-Empty "${___destination}") -eq 0)) {
		return 1
	}

	$___process = ZIP-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___current_path = Get-Location
	$null = Set-Location -Path "${___source}"
	$___process = ZIP-Create "${___destination}" "*"
	$null = Set-Location -Path "${___current_path}"
	$null = Remove-Variable -Name ___current_path
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHOCOLATEY-Publish {
	param (
		[string]$___target,
		[string]$___destination
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___destination}") -eq 0)) {
		return 1
	}


	# execute
	$null = FS-Make-Directory "${___destination}"
	$___process = FS-Copy-File `
		"${___target}" `
		"${___destination}\$(Split-Path -Leaf -Path "${___target}")"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHOCOLATEY-Setup {
	# validate input
	$___process = OS-Is-Command-Available "choco"
	if ($___process -eq 0) {
		$null = choco upgrade chocolatey -y
		return 0
	}


	# execute
	$___process = HTTP-Download `
		"GET" `
		"https://community.chocolatey.org/install.ps1" `
		"install.ps1"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File ".\install.ps1"
	if ($___process -ne 0) {
		return 1
	}

	$null = Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
	$___process = OS-Exec "powershell" ".\install.ps1"
	if ($___process -ne 0) {
		return 1
	}
	$null = FS-Remove-Silently ".\install.ps1"


	# return status
	return OS-Is-Command-Available "choco"
}




function CHOCOLATEY-Test {
	param(
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = CHOCOLATEY-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___name = Split-Path -Leaf -Path "${___target}"
	$___name = $___name -replace '\-chocolatey.*$', ''


	## test install
	$___current_path = Get-Location
	$null = Set-Location "$(Split-Path -Parent -Path "${___target}")"
	$___arguments = "install ${___name} " `
			+ "--debug " `
			+ "--verbose " `
			+ "--force " `
			+ "--source `".`" "
	$___process = OS-Exec "choco" "${___arguments}"
	$null = Set-Location "${___current_path}"
	$null = Remove-Variable "___current_path"
	if ($___process -ne 0) {
		return 1
	}


	## test uninstall
	$___current_path = Get-Location
	$null = Set-Location "$(Split-Path -Parent -Path "${___target}")"
	$___arguments = "uninstall ${___name} " `
			+ "--debug " `
			+ "--verbose " `
			+ "--force " `
			+ "--source `".`" "
	$___process = OS-Exec "choco" "${___arguments}"
	$null = Set-Location "${___current_path}"
	$null = Remove-Variable "___current_path"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
