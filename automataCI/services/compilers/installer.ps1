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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\c.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\versioners\git.ps1"




function INSTALLER-Setup-Angular {
	# validate input
	$__process =  OS-Is-Command-Available "choco"
	if ($__process -ne 0) {
		return 1
	}

	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")
	$__process =  OS-Is-Command-Available "ng"
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__process = INSTALLER-Setup-Node
	if ($__process -ne 0) {
		return 1
	}
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")


	$__process = OS-Exec "npm" "install -g @angular/cli"
	if ($__process -ne 0) {
		return 1
	}
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")

	$__process =  OS-Is-Command-Available "ng"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function INSTALLER-Setup-C {
	# validate input
	$__process =  OS-Is-Command-Available "choco"
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$__process = OS-Exec "choco" "install gcc-arm-embedded -y"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "choco" "install mingw -y"
	if ($__process -ne 0) {
		return 1
	}

	# BUG: choco fails to install emscripten's dependency properly (git.install)
	#      See: https://github.com/aminya/chocolatey-emscripten/issues/2
	#$__process = OS-Exec "choco" "install emscripten -y"
	#if ($__process -ne 0) {
	#	return 1
	#}


	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")


	# report status
	return 0
}




function INSTALLER-Setup-Go {
	# validate input
	$__process =  OS-Is-Command-Available "choco"
	if ($__process -ne 0) {
		return 1
	}

	$__process =  OS-Is-Command-Available "go"
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__process = OS-Exec "choco" "install go -y"
	if ($__process -ne 0) {
		return 1
	}
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")


	# report status
	$__process = OS-Is-Command-Available "go"
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function INSTALLER-Setup-Nim {
	# validate input
	$__process =  OS-Is-Command-Available "choco"
	if ($__process -ne 0) {
		return 1
	}

	$__process =  OS-Is-Command-Available "nim"
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__process = OS-Exec "choco" "install nim -y"
	if ($__process -ne 0) {
		return 1
	}
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")


	# report status
	$__process = OS-Is-Command-Available "nim"
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function INSTALLER-Setup-Node {
	# validate input
	$__process =  OS-Is-Command-Available "choco"
	if ($__process -ne 0) {
		return 1
	}

	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")
	$__process =  OS-Is-Command-Available "npm"
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__process = OS-Exec "choco" "install node -y"
	if ($__process -ne 0) {
		return 1
	}
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")

	$__process = OS-Is-Command-Available "node"
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
