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
function 7ZIP-Formulate-Path {
	return $env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_TOOLS + "\" `
			+ "7zip-engine\7zip.exe"
}




function 7ZIP-Is-Available {
	$program = 7ZIP-Formulate-Path
	if (Test-Path -Path $program -PathType leaf) {
		Remove-Variable -Name program
		return 0
	}

	Remove-Variable -Name program
	return 1
}




function 7ZIP-SHA256 {
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




function 7ZIP-Setup {
	$program = 7ZIP-Formulate-Path
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
		Remove-Variable -Name program
		return 1
	}}

	# download the file
	Invoke-WebRequest -Uri $url -OutFile $program

	# wait for download completion
	$elapsedTime = 0
	$downloading = $true
	$timeout = 600
	while ($downloading -and $elapsedTime -lt $timeout) {
		$downloading = !(Test-Path $program)
		Start-Sleep -Seconds 1
		$elapsedTime++
	}

	if ($downloading) {
		return 1
	}

	# checksum the payload
	$checksum = 7ZIP-Sha256 -Path $program

	# check and verdict
	if ($checksum -eq $sha256) {
		Remove-Variable -Name checksum
		Remove-Variable -Name program
		Remove-Variable -Name url
		Remove-Variable -Name sha256
		return 0
	}

	# bad payload. Clean up...
	Remove-Item $program -ErrorAction SilentlyContinue
	Remove-Variable -Name checksum
	Remove-Variable -Name program
	Remove-Variable -Name url
	Remove-Variable -Name sha256
	return 1
}




function 7ZIP-Create-TARXZ {
	param (
		[string]$Source,
		[string]$Destination
	)
	$program = 7ZIP-Formulate-Path


	# create archive
	Set-Location -Path $Source
	$process = Start-Process -Wait `
			-Filepath "$program" `
			-NoNewWindow `
			-ArgumentList "a -ttar `"$Destination.tar`" ." `
			-PassThru
	if ($process.ExitCode -ne 0) {
		Remove-Variable -Name program
		return 1
	}

	$process = Start-Process -Wait `
			-Filepath "$program" `
			-NoNewWindow `
			-ArgumentList "a -ttar `"$Destination.tar.xz`" `"$Destination.tar`"" `
			-PassThru
	if ($process.ExitCode -ne 0) {
		Remove-Variable -Name program
		return 1
	}

	Remove-Variable -Name program
	return 0
}
