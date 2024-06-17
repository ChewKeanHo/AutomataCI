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
		$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_DOCS}"
		$__dest = "${_directory}\docs"

		$___process = FS-Is-Directory "${__source}"
		if ($___process -ne 0) {
			return 10 # not applicable
		}

		$null = I18N-Assemble "${__source}" "${__dest}"
		$null = FS-Make-Directory "${__dest}"
		$___process = FS-Copy-All "${__source}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		return 10 # handled by lib packager
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # handled by wasm instead
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		$__dest = "${_directory}\assets\$(FS-Get-File "${_target}")"

		$null = I18N-Assemble "${_target}" "${__dest}"
		$null = FS-Make-Directory "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}

		$__source = "$(FS-Extension-Remove "${_target}" ".wasm").js"
		$___process = FS-Is-File "${__source}"
		if ($___process -eq 0) {
			$__dest = "${__dest}\$(FS-Get-File "${__source}")"
			$null = I18N-Assemble "${__source}" "${__dest}"
			$___process = FS-Copy-File "${__source}" "${__dest}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
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
	} elseif ($(FS-Is-Target-A-PDF "${_target}") -eq 0) {
		return 10 # not applicable
	} else {
		$__dest = "${_directory}\bin\${env:PROJECT_SKU}"
		if ($_target_os -eq "windows") {
			$__dest = "${__dest}.exe"
		}

		$null = I18N-Assemble "${_target}" "${__dest}"
		$null = FS-Make-Housing-Directory "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# copy user guide
	Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs" `
	| Where-Object { ($_.Name -like "USER-GUIDES*.pdf") } `
	| ForEach-Object { $__source = $_.FullName
		$__dest = "${_directory}\$(FS-Get-File "${__source}")"
		$null = I18N-Assemble "${__source}" "${__dest}"
		$___process = FS-Copy-File "${__source}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# copy license file
	Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\licenses" `
	| Where-Object { ($_.Name -like "LICENSE*.pdf") } `
	| ForEach-Object { $__source = $_.FullName
		$__dest = "${_directory}\$(FS-Get-File "${__source}")"
		$null = I18N-Assemble "${__source}" "${__dest}"
		$___process = FS-Copy-File "${__source}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# report status
	return 0
}
