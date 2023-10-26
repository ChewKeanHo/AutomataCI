# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	exit 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




function PACKAGE-Assemble-CHOCOLATEY-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Chocolatey "${_target}") -eq 0) {
		# accepted
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	} else {
		return 10 # not applicable
	}


	# assemble the package
	$null = FS-Make-Directory "${_directory}\Data\${env:PROJECT_PATH_SOURCE}"
	$null = FS-Make-Directory "${_directory}\Data\${env:PROJECT_PYTHON}"
	$null = FS-Make-Directory "${_directory}\Data\automataCI"

	$__process = FS-Copy-All `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}" `
		"${_directory}\Data\${env:PROJECT_PATH_SOURCE}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-All `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}" `
		"${_directory}\Data\${env:PROJECT_PYTHON}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-All `
		"${env:PROJECT_PATH_ROOT}\automataCI" `
		"${_directory}\Data\automataCI"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-File `
		"${env:PROJECT_PATH_ROOT}\CONFIG.toml" `
		"${_directory}\Data"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-File `
		"${env:PROJECT_PATH_ROOT}\ci.cmd" `
		"${_directory}\Data"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-File `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\icons\icon-128x128.png" `
		"${_directory}\icon.png"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-File `
		"${env:PROJECT_PATH_ROOT}\README.md" `
		"${_directory}\README.md"
	if ($__process -ne 0) {
		return 1
	}


	# REQUIRED: chocolatey required tools\ directory
	$__process = FS-Make-Directory "${_directory}\tools"
	if ($__process -ne 0) {
		return 1
	}


	# OPTIONAL: chocolatey tools\chocolateyBeforeModify.ps1
	OS-Print-Status info "scripting tools\chocolateyBeforeModify.ps1..."
	$__process = FS-Write-File "${_directory}\tools\chocolateyBeforeModify.ps1" @"
# REQUIRED - BEGIN EXECUTION
Write-Host "Performing pre-configurations..."
"@
	if ($__process -ne 0) {
		return 1
	}


	# REQUIRED: chocolatey tools\chocolateyinstall.ps1
	OS-Print-Status info "scripting tools\chocolateyinstall.ps1..."
	$__process = FS-Write-File "${_directory}\tools\chocolateyinstall.ps1" @"
# REQUIRED - PREPARING INSTALLATION
`$tools_dir = "`$(Split-Path -Parent -Path `$MyInvocation.MyCommand.Definition)"
`$data_dir = "`$(Split-Path -Parent -Path `$tools_dir)\Data"
`$root_dir = "`$(Split-Path -Parent -Path `$tools_dir)"
`$current_dir = (Get-Location).Path




# REQUIRED - BEGIN EXECUTION
# Materialize the binary
Write-Host "Building ${env:PROJECT_SKU} (${env:PROJECT_VERSION})..."
Set-Location "`$data_dir"
.\ci.cmd setup
if (`$LASTEXITCODE -ne 0) {
	Set-Location "`$current_dir"
	Set-PowerShellExitCode 1
	return
}

.\ci.cmd prepare
if (`$LASTEXITCODE -ne 0) {
	Set-Location "`$current_dir"
	Set-PowerShellExitCode 1
	return
}

.\ci.cmd materialize
if (`$LASTEXITCODE -ne 0) {
	Set-Location "`$current_dir"
	Set-PowerShellExitCode 1
	return
}

if (-not (Test-Path "`${data_dir}\bin\${env:PROJECT_SKU}.exe")) {
	Set-Location "`$current_dir"
	Write-Host "Compile Failed. Missing executable."
	Set-PowerShellExitCode 1
	return
}


Write-Host "assembling workspace for installation..."
Move-Item -Path "`${data_dir}\bin" -Destination "`${root_dir}"
Move-Item -Path "`${data_dir}\lib" -Destination "`${root_dir}"
Set-Location "`$current_dir"
Remove-Item `$data_dir -Force -Recurse -ErrorAction SilentlyContinue
"@
	if ($__process -ne 0) {
		return 1
	}


	# REQUIRED: chocolatey tools\chocolateyuninstall.ps1
	OS-Print-Status info "scripting tools\chocolateyuninstall.ps1..."
	$__process = FS-Write-File "${_directory}\tools\chocolateyuninstall.ps1" @"
# REQUIRED - PREPARING UNINSTALLATION
Write-Host "Uninstalling ${env:PROJECT_SKU} (${env:PROJECT_VERSION})..."
"@
	if ($__process -ne 0) {
		return 1
	}


	# REQUIRED: chocolatey xml.nuspec file
	OS-Print-Status info "scripting ${env:PROJECT_SKU}.nuspec..."
	$__process = FS-Write-File "${_directory}\${env:PROJECT_SKU}.nuspec" @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
	<metadata>
		<id>${env:PROJECT_SKU}</id>
		<title>${env:PROJECT_NAME}</title>
		<version>${env:PROJECT_VERSION}</version>
		<authors>${env:PROJECT_CONTACT_NAME}</authors>
		<owners>${env:PROJECT_CONTACT_NAME}</owners>
		<projectUrl>${env:PROJECT_CONTACT_WEBSITE}</projectUrl>
		<license type="expression">${env:PROJECT_LICENSE}</license>
		<description>${env:PROJECT_PITCH}</description>
		<readme>README.md</readme>
		<icon>icon.png</icon>
	</metadata>
	<dependencies>
		<dependency id="chocolatey" version="0.9.8.21" />
		<dependency id="python" version="3.12.0" />
	</dependencies>
	<files>
		<file src="README.md" target="README.md" />
		<file src="icon.png" target="icon.png" />
		<file src="Data\**" target="Data" />
		<file src="tools\**" target="tools" />
	</files>
</package>
"@
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
