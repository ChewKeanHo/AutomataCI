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
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function XZ-Create {
	param (
		[string]$___source
	)


	# validate input
	$___process = XZ-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${___source}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___source}"
	if ($___process -eq 0) {
		return 1
	}


	# create .gz compressed target
	$___source = $___source -replace "\.xz$"
	$___process = OS-Exec "xz" "-9 --compress `"${___source}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function XZ-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "xz"
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}
