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




function PACKAGE-Assemble-HOMEBREW-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	if ($(FS-Is-Target-A-Homebrew "${_target}") -ne 0) {
		return 10 # not applicable
	}


	# assemble the package
	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}"
	$__dest = "${_directory}\${env:PROJECT_PATH_SOURCE}"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$null = FS-Make-Directory "${__dest}"
	$___process = FS-Copy-All "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\.ci"
	$__dest = "${_directory}\${env:PROJECT_PATH_SOURCE}\.ci"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$null = FS-Make-Directory "${__dest}"
	$___process = FS-Copy-All "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}"
	$__dest = "${_directory}\${env:PROJECT_RUST}"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$null = FS-Make-Directory "${__dest}"
	$___process = FS-Copy-All "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}\.ci"
	$__dest = "${_directory}\${env:PROJECT_RUST}\.ci"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$null = FS-Make-Directory "${__dest}"
	$___process = FS-Copy-All "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$__source = "${env:PROJECT_PATH_ROOT}\automataCI"
	$__dest = "${_directory}"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$null = FS-Make-Directory "${__dest}"
	$___process = FS-Copy-All "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$__source = "${env:PROJECT_PATH_ROOT}\CONFIG.toml"
	$__dest = "${_directory}"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$null = FS-Make-Directory "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$__dest = "${_directory}\${env:PROJECT_RUST}\Cargo.toml"
	$null = I18N-Create "${__dest}"
	$___process = RUST-Create-CARGO-TOML `
		"${__dest}" `
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


	# script formula.rb
	$__dest = "${_directory}\formula.rb"
	$null = I18N-Create "${__dest}"
	$___process = FS-Write-File "${__dest}" @"
class ${env:PROJECT_SKU_TITLECASE} < Formula
  desc "${env:PROJECT_PITCH}"
  homepage "${env:PROJECT_CONTACT_WEBSITE}"
  license "${env:PROJECT_LICENSE}"
  url "${env:PROJECT_HOMEBREW_SOURCE_URL}/${env:PROJECT_VERSION}/{{ TARGET_PACKAGE }}"
  sha256 "{{ TARGET_SHASUM }}"


  def install
    system "./automataCI/ci.sh.ps1 setup"
    system "./automataCI/ci.sh.ps1 prepare"
    system "./automataCI/ci.sh.ps1 materialize"
    chmod 0755, "bin/${env:PROJECT_SKU}"
    bin.install "bin/${env:PROJECT_SKU}"
  end

  test do
    system "./automataCI/ci.sh.ps1 setup"
    system "./automataCI/ci.sh.ps1 prepare"
    system "./automataCI/ci.sh.ps1 materialize"
    assert_predicate ./bin/${env:PROJECT_SKU}, :exist?
  end
end
"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
