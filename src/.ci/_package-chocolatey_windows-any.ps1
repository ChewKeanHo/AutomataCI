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




function PACKAGE-Assemble-CHOCOLATEY-Content {
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

		$_package = "lib${env:PROJECT_SKU}"
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
		$__dest = "${_directory}\bin\${env:PROJECT_SKU}.exe"

		$null = I18N-Assemble "${_target}" "${__dest}"
		$null = FS-Make-Housing-Directory "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}

		$_package = "${env:PROJECT_SKU}"
	}


	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\icons\icon-128x128.png"
	$__dest = "${_directory}\icon.png"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}

	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_README}"
	$__dest = "${_directory}\${env:PROJECT_README}"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# REQUIRED: chocolatey required tools\ directory
	$__dest = "${_directory}\tools"
	$null = I18N-Create "${__dest}"
	$___process = FS-Make-Directory "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# OPTIONAL: chocolatey tools\chocolateyBeforeModify.ps1
	$__dest = "${_directory}\tools\chocolateyBeforeModify.ps1"
	$null = I18N-Create "${__dest}"
	$___process = FS-Write-File "${__dest}" @"
# REQUIRED - BEGIN EXECUTION
Write-Host "Performing pre-configurations..."
"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# REQUIRED: chocolatey tools\chocolateyinstall.ps1
	$__dest = "${_directory}\tools\chocolateyinstall.ps1"
	$null = I18N-Create "${__dest}"
	$___process = FS-Write-File "${__dest}" @"
# REQUIRED - PREPARING INSTALLATION
Write-Host "Installing ${env:PROJECT_SKU} (${env:PROJECT_VERSION})..."

"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# REQUIRED: chocolatey tools\chocolateyuninstall.ps1
	$__dest = "${_directory}\tools\chocolateyuninstall.ps1"
	$null = I18N-Create "${__dest}"
	$___process = FS-Write-File "${__dest}" @"
# REQUIRED - PREPARING UNINSTALLATION
Write-Host "Uninstalling ${env:PROJECT_SKU} (${env:PROJECT_VERSION})..."

"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# REQUIRED: chocolatey xml.nuspec file
	$__dest = "${_directory}\${env:PROJECT_SKU}.nuspec"
	$null = I18N-Create "${__dest}"
	$___process = FS-Write-File "${__dest}" @"
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
		<readme>${env:PROJECT_README}</readme>
		<icon>icon.png</icon>
	</metadata>
	<dependencies>
		<dependency id="chocolatey" version="${env:PROJECT_CHOCOLATEY_VERSION}" />
	</dependencies>
	<files>
		<file src="${env:PROJECT_README}" target="${env:PROJECT_README}" />
		<file src="icon.png" target="icon.png" />

"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}

	$___process = FS-Is-Directory-Empty "${_directory}\bin"
	if ($___process -ne 0) {
		$___process = FS-Append-File "${__dest}" @"
		<file src="bin\**" target="bin" />

"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}
	}

	$___process = FS-Is-Directory-Empty "${_directory}\lib"
	if ($___process -ne 0) {
		$___process = FS-Append-File "${__dest}" @"
		<file src="lib\**" target="lib" />

"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}
	}

	$___process = FS-Append-File "${__dest}" @"
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
