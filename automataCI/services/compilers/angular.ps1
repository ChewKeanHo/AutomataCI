# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




function ANGULAR-Build {
	# validate input
	$___process = ANGULAR-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = OS-Sync
		# WARNING: DO NOT CHANGE - ng is not a win32 exe so OS-Exec will
		#                          fail so bad. Leave this as it is.
	$null = Invoke-Expression "ng build"
	if ($?) {
		return 0
	}


	# return status
	return 1
}




function ANGULAR-Is-Available {
	# execute
	$null = OS-Sync

	$___process = OS-Is-Command-Available "npm"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "ng"
	if ($___process -ne 0) {
		return 1
	}


	# report status
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




function ANGULAR-Test {
	# validate input
	$___process = ANGULAR-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = OS-Sync
		# WARNING: DO NOT CHANGE - ng is not a win32 exe so OS-Exec will
		#                          fail so bad. Leave this as it is.
	$null = Invoke-Expression "ng test --no-watch --code-coverage"
	if ($?) {
		return 0
	}


	# return status
	return 1
}
