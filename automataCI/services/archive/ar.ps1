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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function AR-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "ar"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function AR-Create {
	param (
		[string]$___name,
		[string]$___list
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___list}") -eq 0)) {
		return 1
	}

	$___process = AR-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "ar" "cr ${___name} ${___list}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function AR-Extract {
	param (
		[string]$___file
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___file}") -eq 0) {
		return 1
	}

	$___process = AR-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "ar" "-x `"${___file}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
