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
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function MD5-Create-From-File {
	param (
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


	# execute
	$___hasher = [System.Security.Cryptography.MD5]::Create("MD5")
	$___stream = [System.IO.File]::OpenRead($___target)
	$___hash = [System.BitConverter]::ToString($___hasher.ComputeHash($___stream))
	$null = $___stream.Close()


	# report status
	return $___hash.Replace("-", "").ToLower()
}




function MD5-Is-Available {
	# execute
	$___md5 = [System.Security.Cryptography.MD5]::Create("MD5")
	if ($___md5) {
		return 0
	}


	# report status
	return 1
}
