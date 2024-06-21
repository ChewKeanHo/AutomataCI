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




function PACKAGE-Assemble-MSI-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	switch ("${_target_os}") {
	{ $_ -in "any", "windows" } {
		# accepted
	} default {
		return 10 # not supported
	}}

	switch (${_target_arch}) {
	{ $_ -in "any", "amd64", "arm64", "i386", "arm" } {
		# accepted
	} default {
		return 10 # not supported
	}}


	# download required UI extensions into designated ext/ directory
	$__toolkit_ui = 'WixToolset.UI.wixext'
	$__dest = "wixext4\${__toolkit_ui}.dll"
	$null = I18N-Assemble "${__toolkit_ui}" "${_directory}\ext\${__dest}"
	$___process = DOTNET-Add "${__toolkit_ui}" "4.0.3" "${_directory}\ext" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# processing target
	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		# unpack to the designated lib/ directory
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
		# copy main program to the designated bin/ directory
		$__dest = "${_directory}\bin\${env:PROJECT_SKU}.exe"

		$null = I18N-Assemble "${_target}" "${__dest}"
		$null = FS-Make-Housing-Directory "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# copy README.md into the designated docs/ directory
	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_README}"
	$__dest = "${_directory}\docs\${env:PROJECT_README}"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# copy user guide files to the designated docs/ directory
	Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs" `
	| Where-Object { ($_.Name -like "USER-GUIDES*.pdf") } `
	| ForEach-Object { $__source = $_.FullName
		$__dest = "${_directory}\docs\$(FS-Get-File "${__source}")"
		$null = I18N-Assemble "${__source}" "${__dest}"
		$___process = FS-Copy-File "${__source}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# copy PDF license files to the designated docs/ directory
	Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\licenses" `
	| Where-Object { ($_.Name -like "LICENSE*.pdf") } `
	| ForEach-Object { $__source = $_.FullName
		$__dest = "${_directory}\docs\$(FS-Get-File "${__source}")"
		$null = I18N-Assemble "${__source}" "${__dest}"
		$___process = FS-Copy-File "${__source}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# copy RTF license files to the designated docs/ directory
	Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\licenses" `
	| Where-Object { ($_.Name -like "LICENSE*.rtf") } `
	| ForEach-Object { $__source = $_.FullName
		$__dest = "${_directory}\docs\$(FS-Get-File "${__source}")"
		$null = I18N-Assemble "${__source}" "${__dest}"
		$___process = FS-Copy-File "${__source}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# copy icon.ico file to the designated base directory
	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\icons\icon.ico"
	$__dest = "${_directory}\icon.ico"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# copy MSI banner jpg file to the designated base directory
	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\icons\msi-banner.jpg"
	$__dest = "${_directory}\msi-banner.jpg"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# copy MSI dialog jpg file to the designated base directory
	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\icons\msi-dialog.jpg"
	$__dest = "${_directory}\msi-dialog.jpg"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	## OPTIONAL - create a '[LANG].wxs' recipe if you wish to override one
	##            and place it inside the designated base directory.
	##            Otherwise, AutomataCI shall create one for you using its
	##            packaging structure.


	# report status
	return 0
}
