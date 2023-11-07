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
function HTTP-Download {
	param (
		[string]$__method,
		[string]$__url,
		[string]$__filepath,
		[string]$__shasum_type,
		[string]$__shasum_value,
		[string]$__auth_header
	)


	# validate input
	if ([string]::IsNullOrEmpty($__url) -or [string]::IsNullOrEmpty($__filepath)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($__method)) {
		$__method = "GET"
	}


	# execute
	## clean up workspace
	$null = Remove-Item $__filepath -Force -Recurse -ErrorAction SilentlyContinue
	$null = FS-Make-Directory (Split-Path -Path $__filepath) -ErrorAction SilentlyContinue

	## download payload
	if (-not [string]::IsNullOrEmpty($__auth_header)) {
		$null = Invoke-RestMethod `
			-OutFile $__filepath `
			-Headers $__auth_header `
			-Method $__method `
			-Uri $__url
	} else {
		$null = Invoke-RestMethod -OutFile $__filepath -Method $__method -Uri $__url
	}

	if (-not (Test-Path -Path $__filepath)) {
		return 1
	}

	## checksum payload
	if ([string]::IsNullOrEmpty($__shasum_type) -or
		[string]::IsNullOrEmpty($__shasum_value)) {
		return 1
	}

	switch ($__shasum_type) {
	'1' {
		$__hasher = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
	} '224' {
		return 1
	} '256' {
		$__hasher = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
	} '384' {
		$__hasher = New-Object System.Security.Cryptography.SHA384CryptoServiceProvider
	} '512' {
		$__hasher = New-Object System.Security.Cryptography.SHA512CryptoServiceProvider
	} '512224' {
		return 1
	} '512256' {
		return 1
	} Default {
		return 1
	}}

	$__fileStream = [System.IO.File]::OpenRead($__filepath)
	$__hash = $__hasher.ComputeHash($__fileStream)
	$__hash = [System.BitConverter]::ToString($__hash).Replace("-", "").ToLower()
	if ($__hash -ne $__shasum_value) {
		return 1
	}


	# report status
	return 0
}




function HTTP-Setup {
	return 0 # using PowerShell native function
}
