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
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\rust.ps1"




function PACKAGE-Assemble-CARGO-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	$___process = FS-Is-Target-A-Cargo "${_target}"
	if ($___process -ne 0) {
		return 10
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_RUST}") -eq 0) {
		return 10
	}


	# assemble the cargo package
	$_source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}\"
	$null = I18N-Assemble "${_source}" "${_directory}"
	$___process = FS-Copy-All "${_source}" "${_directory}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$_source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_CARGO_README}"
	$_dest = "${_directory}\README.md"
	$null = I18N-Assemble "${_source}" "${_dest}"
	$___process = FS-Copy-File "${_source}" "${_dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$_dest = "${_directory}\Cargo.toml"
	$null = FS-Remove-Silently "${_directory}\Cargo.lock"
	$null = FS-Remove-Silently "${_directory}\.ci"
	$null = I18N-Create "${_dest}"
	$___process = RUST-Create-CARGO-TOML `
		"${_dest}" `
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


	# report status
	return 0
}
