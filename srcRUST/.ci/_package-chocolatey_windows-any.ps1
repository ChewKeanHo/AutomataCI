# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	exit 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\rust.ps1"




function PACKAGE-Assemble-CHOCOLATEY-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	if ($(FS-Is-Target-A-Chocolatey "${_target}") -ne 0) {
		return 10 # not applicable
	}


	# assemble the package
	$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\"
	$___dest = "${_directory}\Data\${env:PROJECT_PATH_SOURCE}"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$null = FS-Make-Directory "${___dest}"
	$___process = FS-Copy-All "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\.ci\"
	$___dest = "${_directory}\Data\${env:PROJECT_PATH_SOURCE}\.ci"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$null = FS-Make-Directory "${___dest}"
	$___process = FS-Copy-All "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}\"
	$___dest = "${_directory}\Data\${env:PROJECT_RUST}"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$null = FS-Make-Directory "${___dest}"
	$___process = FS-Copy-All "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}\.ci\"
	$___dest = "${_directory}\Data\${env:PROJECT_RUST}\.ci"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$null = FS-Make-Directory "${___dest}"
	$___process = FS-Copy-All "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___source = "${env:PROJECT_PATH_ROOT}\automataCI\"
	$___dest = "${_directory}\Data\automataCI"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$null = FS-Make-Directory "${___dest}"
	$___process = FS-Copy-All "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___source = "${env:PROJECT_PATH_ROOT}\CONFIG.toml"
	$___dest = "${_directory}\Data"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$___process = FS-Copy-File "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\icons\icon-128x128.png"
	$___dest = "${_directory}\icon.png"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$___process = FS-Copy-File "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___source = "${env:PROJECT_PATH_ROOT}\README.md"
	$___dest = "${_directory}\README.md"
	$null = I18N-Assemble "${___source}" "${___dest}"
	$___process = FS-Copy-File "${___source}" "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$___dest = "${_directory}\Data\${env:PROJECT_RUST}\Cargo.toml"
	$null = I18N-Create "${___dest}"
	$___process = RUST-Create-CARGO-TOML `
		"${___dest}" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}\Cargo.toml" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_PITCH}" `
		"${env:PROJECT_RUST_EDITION}" `
		"${env:PROJECT_LICENSE}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_SOURCE_URL}" `
		"README.md" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_EMAIL}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# REQUIRED: chocolatey required tools\ directory
	$___dest = "${_directory}\tools"
	$null = I18N-Create "${___dest}"
	$___process = FS-Make-Directory "${___dest}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# OPTIONAL: chocolatey tools\chocolateyBeforeModify.ps1
	$___dest = "${_directory}\tools\chocolateyBeforeModify.ps1"
	$null = I18N-Create "${___dest}"
	$___process = FS-Write-File "${___dest}" @"
# REQUIRED - BEGIN EXECUTION
Write-Host "Performing pre-configurations..."
"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# REQUIRED: chocolatey tools\chocolateyinstall.ps1
	$___dest = "${_directory}\tools\chocolateyinstall.ps1"
	$null = I18N-Create "${___dest}"
	$___process = FS-Write-File "${___dest}" @"
# REQUIRED - PREPARING INSTALLATION
`$tools_dir = "`$(Split-Path -Parent -Path `$MyInvocation.MyCommand.Definition)"
`$data_dir = "`$(Split-Path -Parent -Path `$tools_dir)\Data"
`$root_dir = "`$(Split-Path -Parent -Path `$tools_dir)"
`$current_dir = (Get-Location).Path




# REQUIRED - BEGIN EXECUTION
# Materialize the binary
Write-Host "Building ${env:PROJECT_SKU} (${env:PROJECT_VERSION})..."
Set-Location "`$data_dir"
.\automataCI\ci.sh.ps1 setup
if (`$LASTEXITCODE -ne 0) {
	Set-Location "`$current_dir"
	Set-PowerShellExitCode 1
	return
}

.\automataCI\ci.sh.ps1 prepare
if (`$LASTEXITCODE -ne 0) {
	Set-Location "`$current_dir"
	Set-PowerShellExitCode 1
	return
}

.\automataCI\ci.sh.ps1 materialize
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
if (Test-Path -PathType Container -Path "`${data_dir}\bin") {
	Move-Item -Path "`${data_dir}\bin" -Destination "`${root_dir}"
}
if (Test-Path -PathType Container -Path "`${data_dir}\lib") {
	Move-Item -Path "`${data_dir}\lib" -Destination "`${root_dir}"
}
Set-Location "`$current_dir"
Remove-Item `$data_dir -Force -Recurse -ErrorAction SilentlyContinue
"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# REQUIRED: chocolatey tools\chocolateyuninstall.ps1
	$___dest = "${_directory}\tools\chocolateyuninstall.ps1"
	$null = I18N-Create "${___dest}"
	$___process = FS-Write-File "${___dest}" @"
# REQUIRED - PREPARING UNINSTALLATION
Write-Host "Uninstalling ${env:PROJECT_SKU} (${env:PROJECT_VERSION})..."
"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# REQUIRED: chocolatey xml.nuspec file
	$___dest = "${_directory}\${env:PROJECT_SKU}.nuspec"
	$null = I18N-Create "${___dest}"
	$___process = FS-Write-File "${___dest}" @"
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
		<dependency id="rust" version="1.76.0" />
	</dependencies>
	<files>
		<file src="README.md" target="README.md" />
		<file src="icon.png" target="icon.png" />
		<file src="Data\**" target="Data" />
		<file src="tools\**" target="tools" />
	</files>
</package>
"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
