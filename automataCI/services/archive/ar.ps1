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




function AR-Is-Available {
	# execute
	$__process = Get-Command "ar" -ErrorAction SilentlyContinue
	if (-not ($__process)) {
		return 1
	}


	# report status
	return 0
}




function AR-Create {
	param (
		[string]$__name,
		[string]$__list
	)


	# validate input
	if ([string]::IsNullOrEmpty($__name) -or [string]::IsNullOrEmpty($__list)) {
		return 1
	}

	$__process = AR-Is-Available
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$__process = OS-Exec "ar" "r ${__name} ${__list}"


	# report status
	return $__process
}
