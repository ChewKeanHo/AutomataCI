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
function HTTP-Download {
	param (
		[string]$___method,
		[string]$___url,
		[string]$___filepath,
		[string]$___shasum_type,
		[string]$___shasum_value,
		[string]$___auth_header
	)


	# validate input
	if ([string]::IsNullOrEmpty($___url) -or [string]::IsNullOrEmpty($___filepath)) {
		return 1
	}

	if ((-not (Get-Command curl -ErrorAction SilentlyContinue)) -and
		(-not (Get-Command wget -ErrorAction SilentlyContinue))) {
		return 1
	}

	if ([string]::IsNullOrEmpty($___method)) {
		$___method = "GET"
	}


	# execute
	## clean up workspace
	$null = Remove-Item $___filepath -Force -Recurse -ErrorAction SilentlyContinue
	$null = FS-Make-Directory (Split-Path -Path $___filepath) -ErrorAction SilentlyContinue
	$___user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"

	## download payload
	if (-not [string]::IsNullOrEmpty($___auth_header)) {
		if (Get-Command curl -ErrorAction SilentlyContinue) {
			$null = curl --location `
				--header $___user_agent `
				--header $___auth_header `
				--output $___filepath `
				--request $___method `
				$___url
			if ($LASTEXITCODE -ne 0) {
				$null = Remove-Item $___filepath `
					-Force `
					-Recurse `
					-ErrorAction SilentlyContinue
				return 1
			}
		} elseif (Get-Command wget -ErrorAction SilentlyContinue) {
			$null = wget --max-redirect 16 `
				--header $___user_agent `
				--header=$___auth_header `
				--output-file=$___filepath `
				--method=$___method `
				$___url
			if ($LASTEXITCODE -ne 0) {
				$null = Remove-Item $___filepath `
					-Force `
					-Recurse `
					-ErrorAction SilentlyContinue
				return 1
			}
		} else {
			$null = Remove-Item $___filepath `
				-Force `
				-Recurse `
				-ErrorAction SilentlyContinue
			return 1
		}
	} else {
		if (Get-Command curl -ErrorAction SilentlyContinue) {
			$null = curl --location `
				--header $___user_agent `
				--output $___filepath `
				--request $___method `
				$___url
			if ($LASTEXITCODE -ne 0) {
				$null = Remove-Item $___filepath `
					-Force `
					-Recurse `
					-ErrorAction SilentlyContinue
				return 1
			}
		} elseif (Get-Command wget -ErrorAction SilentlyContinue) {
			$null = wget --max-redirect 16 `
				--header $___user_agent `
				--output-file=$___filepath `
				--method=$___method `
				$___url
			if ($LASTEXITCODE -ne 0) {
				$null = Remove-Item $___filepath `
					-Force `
					-Recurse `
					-ErrorAction SilentlyContinue
				return 1
			}
		} else {
			$null = Remove-Item $___filepath `
				-Force `
				-Recurse `
				-ErrorAction SilentlyContinue
			return 1
		}
	}

	if (-not (Test-Path -Path $___filepath)) {
		return 1
	}

	## checksum payload
	if ([string]::IsNullOrEmpty($___shasum_type) -or
		[string]::IsNullOrEmpty($___shasum_value)) {
		return 0
	}

	switch ($___shasum_type) {
	'1' {
		$___hasher = New-Object `
			System.Security.Cryptography.SHA1CryptoServiceProvider
	} '224' {
		return 1
	} '256' {
		$___hasher = New-Object `
			System.Security.Cryptography.SHA256CryptoServiceProvider
	} '384' {
		$___hasher = New-Object `
			System.Security.Cryptography.SHA384CryptoServiceProvider
	} '512' {
		$___hasher = New-Object `
			System.Security.Cryptography.SHA512CryptoServiceProvider
	} '512224' {
		return 1
	} '512256' {
		return 1
	} Default {
		return 1
	}}

	$___fileStream = [System.IO.File]::OpenRead($___filepath)
	$___hash = $___hasher.ComputeHash($___fileStream)
	$___hash = [System.BitConverter]::ToString($___hash).Replace("-", "").ToLower()
	if ($___hash -ne $___shasum_value) {
		return 1
	}


	# report status
	return 0
}




function HTTP-Is-Available {
	# execute
	if (Get-Command curl -ErrorAction SilentlyContinue) {
		return 0
	}


	# report status
	return 1
}




function HTTP-Setup {
	# validate input
	if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
		return 1
	}

	if (Get-Command curl -ErrorAction SilentlyContinue) {
		return 0
	}

	choco install curl
	if ($LASTEXITCODE -ne 0) {
		return 1
	}


	# report status
	return 1
}
