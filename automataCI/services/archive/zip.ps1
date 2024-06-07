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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"




function ZIP-Create {
	param (
		[string]$___destination,
		[string]$___source
	)


	# execute
	try {
		$null = Compress-Archive -Update `
			-DestinationPath $___destination `
			-Path $___source
		$___process = FS-Is-File "${___destination}"
		if ($___process -eq 0) {
			return 0
		}
	} catch {
		return 1
	}


	# report status
	return 1
}




function ZIP-Extract {
	param (
		[string]$___destination,
		[string]$___source
	)


	# validate input
	$___process = FS-Is-Directory "${___destination}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___source}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Make-Directory "${___destination}"
	try {
		$null = Expand-Archive -Path $___source -DestinationPath $___destination
	} catch {
		return 1
	}

	# report status
	return 0
}




function ZIP-Is-Available {
	# report status
	return 0
}
