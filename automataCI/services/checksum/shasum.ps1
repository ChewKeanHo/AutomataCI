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




function SHASUM-Create-From-File {
	param (
		[string]$___target,
		[string]$___algo
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___algo}") -eq 0)) {
		return ""
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return ""
	}


	# execute
	switch ($___algo) {
	'1' {
		$___hasher = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
	} '224' {
		return ""
	} '256' {
		$___hasher = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
	} '384' {
		$___hasher = New-Object System.Security.Cryptography.SHA384CryptoServiceProvider
	} '512' {
		$___hasher = New-Object System.Security.Cryptography.SHA512CryptoServiceProvider
	} '512224' {
		return ""
	} '512256' {
		return ""
	} Default {
		return ""
	}}

	$___fileStream = [System.IO.File]::OpenRead($___target)
	$___hash = $___hasher.ComputeHash($___fileStream)
	return [System.BitConverter]::ToString($___hash).Replace("-", "").ToLower()
}




function SHASUM-Is-Available {
	# execute
	$___ret = [System.Security.Cryptography.SHA1]::Create("SHA1")
	if (-not $___ret) {
		return 1
	}

	$___ret = [System.Security.Cryptography.SHA256]::Create("SHA256")
	if (-not $___ret) {
		return 1
	}

	$___ret = [System.Security.Cryptography.SHA384]::Create("SHA384")
	if (-not $___ret) {
		return 1
	}

	$___ret = [System.Security.Cryptography.SHA512]::Create("SHA512")
	if (-not $___ret) {
		return 1
	}


	# report status
	return 0
}
