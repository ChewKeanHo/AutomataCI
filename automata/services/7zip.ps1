# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
function Formulate-Path-7Zip {
	return $env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_TOOLS + "\" `
			+ "7zip-engine\7zip.exe"
}




function Check-7Zip-Is-Available {
	if (Test-Path -Path Formulate-Path-7Zip -PathType leaf) {
		return 0
	}

	return 1
}




function SHA256-File {
	param (
		[string] $path
	)

	$stream = New-Object System.IO.FileStream($path, 'Open', 'Read', 'ReadWrite')
	$sha = New-Object -Type System.Security.Cryptography.SHA256Managed
	$bytes = $sha.ComputeHash($stream)
	$stream.Dispose()
	$stream.Close()
	$sha.Dispose()
	return [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
}




function Setup-7Zip {
	$program = Formulate-Path-7Zip
	New-Item -ItemType Directory `
		-Path (Split-Path -Path $program -Parent) `
		-Force `
		| Out-Null

	# configure required values and parameters
	switch ($env:PROJECT_ARCH)
	{ "arm64" {
		$url = "https://www.7-zip.org/a/7z2301-arm64.exe"
		$sha256 = "6fa4cb35cbebb0a46b8bbc22d1686a340e183c1f875d8b714efdc39af93debda"
	} "amd64" {
		$url = "https://www.7-zip.org/a/7z2301-x64.exe"
		$sha256 = "26cb6e9f56333682122fafe79dbcdfd51e9f47cc7217dccd29ac6fc33b5598cd"
	} "i386" {
		$url = "https://www.7-zip.org/a/7z2301.exe"
		$sha256 = "9b6682255bed2e415bfa2ef75e7e0888158d1aaf79370defaa2e2a5f2b003a59"
	} default {
		Write-Host "[ ERROR ] unsupported architecture for 7-Zip."
		Remove-Variable -Name program
		return 1
	}}

	# download the file
	Invoke-WebRequest -Uri $url -OutFile $program

	# checksum the payload
	$checksum = Sha256-File -Path $program

	# check and verdict
	if ($checksum -eq $sha256) {
		Write-Host "[ SUCCESS ]"
		Remove-Variable -Name checksum
		Remove-Variable -Name program
		Remove-Variable -Name url
		Remove-Variable -Name sha256
		return 0
	}

	# bad payload. Clean up...
	Write-Host "[ ERROR ] download failed"
	Remove-Item $program -ErrorAction SilentlyContinue
	Remove-Variable -Name checksum
	Remove-Variable -Name program
	Remove-Variable -Name url
	Remove-Variable -Name sha256
	return 1
}




function Create-TARXZ {
	param (
		[string]$Source,
		[string]$Destination
	)


	# clean up destination path
	Remove-Item (Split-Path -Parent $Destination) `
		-Recurse `
		-Force `
		-ErrorAction SilentlyContinue
	New-Item -ItemType Directory `
		-Force `
		-Path (Split-Path -Parent $Destination) `
		| Out-Null


	# create archive
	Set-Location -Path $Source
	Formulate-Path-7Zip a -ttar "$Destination.tar" .
	Formulate-Path-7Zip a -ttar "$Destination.tar.xz" "$Destination.tar"
	if ($LASTEXITCODE -ne 0) {
		return 1
	}
	return 0
}
