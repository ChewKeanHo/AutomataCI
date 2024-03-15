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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"




function ANGULAR-Build {
	# validate input
	$__process = ANGULAR-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$null = Invoke-Expression "ng build"
	if ($?) {
		return 0
	}


	# return status
	return 1
}




function ANGULAR-Is-Available {
	$null = OS-Sync

	$__program = Get-Command npm -ErrorAction SilentlyContinue
	if (-not $__program) {
		return 1
	}

	$__program = Get-Command ng -ErrorAction SilentlyContinue
	if (-not $__program) {
		return 1
	}

	return 0
}




function ANGULAR-Setup {
	# validate input
	$null = OS-Sync

	$___process = ANGULAR-Is-Available
	if ($___process -eq 0) {
		return 0
	}

	$___process =  OS-Is-Command-Available "npm"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "npm" "install -g @angular/cli"
	if ($___process -ne 0) {
		return 1
	}
	$null = OS-Sync


	# report status
	return 0
}
