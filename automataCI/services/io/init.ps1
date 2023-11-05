# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# determine os
$env:PROJECT_OS = (Get-ComputerInfo).OsName.ToLower()
if (-not ($env:PROJECT_OS -match "microsoft" -or $env:PROJECT_OS -match "windows")) {
	Write-Host "[ ERROR ] unsupported OS."
	exit 1
}
$env:PROJECT_OS = "windows"




# determine arch
switch -regex ((Get-ComputerInfo).CsProcessors.Architecture) {
"x86" {
	$env:PROJECT_ARCH = "i386"
} "MIPS" {
	$env:PROJECT_ARCH = "mips"
} "Alpha" {
	$env:PROJECT_ARCH = "alpha"
} "PowerPC" {
	$env:PROJECT_ARCH = "powerpc"
} "ARM" {
	$env:PROJECT_ARCH = "arm"
} "ia64" {
	$env:PROJECT_ARCH = "ia64"
} "x64" {
	$env:PROJECT_ARCH = "amd64"
} "ARM64" {
	$env:PROJECT_ARCH = "arm64"
} Default {
	Write-Host "[ ERROR ] unsupported architecture."
	exit 1
}}




# determine PROJECT_PATH_PWD
$env:PROJECT_PATH_PWD = Get-Location




# scan for PROJECT_PATH_ROOT
$__pathing = "${env:PROJECT_PATH_PWD}"
$__previous = ""

while (-not ([string]::IsNullOrEmpty($__pathing))) {
	$env:PORJECT_PATH_ROOT += ($__pathing -split "/", 2)[0] + "/"
	$__pathing = ($__pathing -split "/", 2)[1]

	if (Test-Path -Path "${env:PROJECT_PATH_ROOT}automataCI/ci.ps1") {
		break
	}

	if ($__previous -eq $__pathing) {
		Write-Host "[ ERROR ] unable to detect repo root directory from PWD."
		exit 1
	}

	$__previous = $__pathing
}
Remove-Variable -Name __pathing
Remove-Variable -Name __previous
$env:PROJECT_PATH_ROOT = $env:PROJECT_PATH_ROOT.TrimEnd('\')
$env:PROJECT_PATH_AUTOMATA = "automataCI"




# parse repo CI configurations
if (-not (Test-Path -Path "${env:PROJECT_PATH_ROOT}\CONFIG.toml")) {
	Write-Host "[ ERROR ] missing '${env:PROJECT_PATH_ROOT}\CONFIG.toml' config file."
	exit 1
}


foreach ($__line in (Get-Content "${env:PROJECT_PATH_ROOT}\CONFIG.toml")) {
	$__line = $__line -replace '#.*', ''

	if ([string]::IsNullOrEmpty($__line)) {
		continue
	}

	$__key, $__value = $__line -split '=', 2
	$__key = $__key.Trim() -replace '^''|''$|^"|"$'
	$__value = $__value.Trim() -replace '^''|''$|^"|"$'

	Set-Item -Path "env:$__key" -Value $__value
}




# parse repo CI secret configurations
if (Test-Path -Path "${env:PROJECT_PATH_ROOT}\SECRETS.toml" -PathType leaf) {
	foreach ($__line in (Get-Content "${env:PROJECT_PATH_ROOT}\SECRETS.toml")) {
		$__line = $__line -replace '#.*', ''

		if ([string]::IsNullOrEmpty($__line)) {
			continue
		}

		$__key, $__value = $__line -split '=', 2
		$__key = $__key.Trim() -replace '^''|''$|^"|"$'
		$__value = $__value.Trim() -replace '^''|''$|^"|"$'

		Set-Item -Path "env:$__key" -Value $__value
	}
}




# update critical environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
	+ ";" `
	+ [System.Environment]::GetEnvironmentVariable("Path","User")




# report status
return 0
