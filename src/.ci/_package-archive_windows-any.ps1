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
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




function PACKAGE-Assemble-ARCHIVE-Content {
	param(
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# copy main program
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		$___process = FS-Is-Target-A-Docs "${_target}"
		if ($___process -ne 0) {
			return 10 # not applicable
		}

		$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_DOCS}"
		$null = I18N-Copy "${__source}\*" "${_directory}"
		$___process = FS-Copy-All "${__source}" "${_directory}"
		if ($___process -ne 0) {
			$null = I18N-Copy-Failed
			return 1
		}
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		$null = I18N-Copy "${_target}" "${_directory}"
		$___process = Fs-Copy-File "${_target}" "${_directory}"
		if ($___process -ne 0) {
			$null = I18N-Copy-Failed
			return 1
		}
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # handled by wasm instead
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		$null = I18N-Copy "${_target}" "${_directory}"
		$___process = Fs-Copy-File "${_target}" "${_directory}"
		if ($___process -ne 0) {
			$null = I18N-Copy-Failed
			return 1
		}

		$__source = "$($_target -replace '\.wasm.*$', '.js')"
		$___process = FS-Is-File "${__source}"
		if ($___process -eq 0) {
			$null = I18N-Copy "${__source}" "${_directory}"
			$___process = Fs-Copy-File "${__source}" "${_directory}"
			if ($___process -ne 0) {
				$null = I18N-Copy-Failed
				return 1
			}
		}
	} elseif ($(FS-Is-Target-A-Chocolatey "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Cargo "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-MSI "${_target}") -eq 0) {
		return 10 # not applicable
	} else {
		switch (${_target_os}) {
		"windows" {
			$_dest = "${_directory}\${env:PROJECT_SKU}.exe"
		} Default {
			$_dest = "${_directory}\${env:PROJECT_SKU}"
		}}

		$null = I18N-Copy "${_target}" "${_dest}"
		$___process = Fs-Copy-File "${_target}" "${_dest}"
		if ($___process -ne 0) {
			$null = I18N-Copy-Failed
			return 1
		}
	}


	# copy user guide
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\docs\USER-GUIDES-EN.pdf"
	$null = I18N-Copy "${_target}" "${_directory}"
	$___process = FS-Copy-File "${_target}" "${_directory}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}


	# copy license file
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\licenses\LICENSE-EN.pdf"
	$null = I18N-Copy "${_target}" "${_directory}"
	$___process = FS-Copy-File "${_target}" "${_directory}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}


	# report status
	return 0
}
