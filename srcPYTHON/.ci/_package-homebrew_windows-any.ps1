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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\python.ps1"




function PACKAGE-Assemble-HOMEBREW-Content {
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
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		# accepted
	} else {
		return 10 # not applicable
	}


	# assemble the package
	$null = FS-Make-Directory "${_directory}\Data\${env:PROJECT_PATH_SOURCE}"
	$__process = FS-Copy-All "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}" `
		"${_directory}\Data\${env:PROJECT_PATH_SOURCE}"
	if ($__process -ne 0) {
		return 1
	}

	$null = PYTHON-Clean-Artifact "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}"
	$__process = FS-Copy-All "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}" "${_directory}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-All "${env:PROJECT_PATH_ROOT}\automataCI" "${_directory}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-File "${env:PROJECT_PATH_ROOT}\CONFIG.toml" "${_directory}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Copy-File "${env:PROJECT_PATH_ROOT}\ci.cmd" "${_directory}"
	if ($__process -ne 0) {
		return 1
	}


	# script formula.rb
	OS-Print-Status info "scripting formula.rb..."
	$__process = FS-Write-File "${_directory}\formula.rb" @"
class ${env:PROJECT_SKU_TITLECASE} < Formula
  desc "${env:PROJECT_PITCH}"
  homepage "${env:PROJECT_CONTACT_WEBSITE}"
  license "${env:PROJECT_LICENSE}"
  url "${env:PROJECT_HOMEBREW_SOURCE_URL}/${env:PROJECT_VERSION}/{{ TARGET_PACKAGE }}"
  sha256 "{{ TARGET_SHASUM }}"

  depends_on "go" => [:build, :test]

  def install
    system "./ci.cmd setup"
    system "./ci.cmd prepare"
    system "./ci.cmd materialize"
    chmod 0755, "bin/${env:PROJECT_SKU}"
    bin.install "bin/${env:PROJECT_SKU}"
  end

  test do
    system "./ci.cmd setup"
    system "./ci.cmd prepare"
    system "./ci.cmd materialize"
    assert_predicate ./bin/${env:PROJECT_SKU}, :exist?
  end
end
"@
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
