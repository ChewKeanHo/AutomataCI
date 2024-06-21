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
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




function PACKAGE-Assemble-HOMEBREW-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	if ($(STRINGS-Is-Empty "${env:PROJECT_HOMEBREW_URL}") -eq 0) {
		return 10 # disabled explictly
	}

	switch ("${_target_os}") {
	{ $_ -in "any", "darwin", "linux" } {
		# accepted
	} default {
		return 10 # not supported
	}}

	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		$__dest = "${_directory}\lib"

		if ($(FS-Is-Target-A-NPM "${_target}") -eq 0) {
			return 10 # not applicable
		} elseif ($(FS-Is-Target-A-TARGZ "${_target}") -eq 0) {
			# unpack library
			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = TAR-Extract-GZ "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} elseif ($(FS-Is-Target-A-TARXZ "${_target}") -eq 0) {
			# unpack library
			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = TAR-Extract-XZ "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} elseif ($(FS-Is-Target-A-ZIP "${_target}") -eq 0) {
			# unpack library
			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = ZIP-Extract "${__dest}" "${_target}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		} else {
			# copy library file
			$__dest = "${__dest}\$(FS-Get-File "${_target}")"
			$null = I18N-Assemble "${_target}" "${__dest}"
			$null = FS-Make-Directory "${__dest}"
			$___process = FS-Copy-File "${_target}" "${__dest}"
			if ($___process -ne 0) {
				$null = I18N-Assemble-Failed
				return 1
			}
		}
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
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
		# copy main program
		$__dest = "${_directory}\bin\$(FS-Get-File "${_target}")"

		$null = I18N-Assemble "${_target}" "${__dest}"
		$null = FS-Make-Housing-Directory "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# report status
	return 0
}
