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
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\rust.ps1"




function PACKAGE-Assemble-Cargo-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	$__process = FS-Is-Target-A-Cargo "${_target}"
	if ($__process -ne 0) {
		return 10
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_RUST)) {
		return 10
	}


	# assemble the cargo package
	$__process = FS-Copy-All "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}\" "${_directory}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-File "${env:PROJECT_PATH_ROOT}\${env:PROJECT_CARGO_README}" `
		"${_directory}\README.md"
	if ($__process -ne 0) {
		return 1
	}

	$null = FS-Remove-Silently "${_directory}\Cargo.lock"
	$null = FS-Remove-Silently "${_directory}\.ci"
	$__process = RUST-Create-Cargo-TOML `
		"${_directory}\Cargo.toml" `
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
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
