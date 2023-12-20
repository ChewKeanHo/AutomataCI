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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function HOMEBREW-Is-Valid-Formula {
	param (
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Target-A-Homebrew "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	if ($___target -like "*.asc") {
		return 1
	}


	# execute
	if ($___target -like "*.rb") {
		return 1
	}


	# report status
	return 1
}




function HOMEBREW-Publish {
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




function HOMEBREW-Setup {
	# report status
	return 1 # unsupported
}
