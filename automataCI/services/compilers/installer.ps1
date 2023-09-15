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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\docker.ps1"




function INSTALLER-setup {
	# validate input
	$__process = OS-Is-Command-Available "choco"
	if ($__process -eq 0) {
		$null = choco upgrade chocolatey -y
		return 0
	}

	# execute installation
	$null = Invoke-RestMethod "https://community.chocolatey.org/install.ps1" `
			-OutFile "install.ps1"

	$__process = FS-Is-File ".\install.ps1"
	if ($__process -ne 0) {
		return 1
	}

	$null = Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
	$null = .\install.ps1
	if ($LASTEXITCODE -ne 0) {
		return 1
	}
	$null = FS-Remove-Silently ".\install.ps1"

	# return status
	return OS-Is-Command-Available "choco"
}




function INSTALLER-Setup-Curl {
	# validate input
	$__process =  OS-Is-Command-Available "choco"
	if ($__process -ne 0) {
		return 1
	}

	$__process =  OS-Is-Command-Available "curl"
	if ($__process -eq 0) {
		return 0
	}

	# execute
	$__process = OS-Exec "choco" "install curl -y"
	if ($__process -ne 0) {
		return 1
	}

	# report status
	$__process = OS-Is-Command-Available "curl"
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function INSTALLER-Setup-Docker {
	# validate input
	$__process =  OS-Is-Command-Available "choco"
	if ($__process -ne 0) {
		return 1
	}

	$__process = choco list --local-only --exact 'docker-desktop'
	if (-not ($LASTEXITCODE -eq 0 -and $packageList -match $dockerDesktopPackage)) {
		$__process = OS-Exec "choco" "install docker-desktop -y"
		if ($__process -ne 0) {
			return 1
		}
	}

	$__process =  OS-Is-Command-Available "docker"
	if ($__process -ne 0) {
		# NOTE: nothing else can be done since docker is host-specific
		return 0
	}

	# execute
	$__process = DOCKER-Setup-Builder-Multiarch
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function INSTALLER-Setup-Python {
	# validate input
	$__process =  OS-Is-Command-Available "choco"
	if ($__process -ne 0) {
		return 1
	}

	$__process =  OS-Is-Command-Available "python"
	if ($__process -eq 0) {
		return 0
	}

	# execute
	$__process = OS-Exec "choco" "install python -y"
	if ($__process -ne 0) {
		return 1
	}

	# report status
	$__process = OS-Is-Command-Available "python"
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function INSTALLER-Setup-Reprepro {
	return 0  # Windows do not have Reprepro
}