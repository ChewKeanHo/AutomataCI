# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\zip.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	exit 1
}




function PACKAGE-Assemble-LIB-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate project
	if ($(FS-Is-Target-A-Library "${_target}") -ne 0) {
		return 10 # not applicable
	}


	# execute
	$_workspace = "packagers-lib-lib${env:PROJECT_SKU}_${_target_os}-${_target_arch}"
	$_workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${_workspace}"
	$null = FS-Remove-Silently "${_workspace}"

	$__dest = "${_workspace}\lib"
	if ($(FS-Is-Target-A-NPM "${_target}") -eq 0) {
		# copy over - do not modify anymore
		$__dest = "lib${env:PROJECT_SKU}-NPM_${env:PROJECT_VERSION}_js-js.tgz"
		$__dest = "${_directory}\${__dest}"
		$null = I18N-Copy "${_target}" "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Copy-Failed
			return 1
		}

		return 0
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
		# assumed it is a standalone library file
		$null = I18N-Assemble "${_target}" "${__dest}"
		$null = FS-Make-Directory "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# sanity check before proceeding
	$___process = FS-Is-Directory-Empty "${__dest}"
	if ($___process -eq 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# copy README.md
	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_README}"
	$__dest = "${_workspace}\${env:PROJECT_README}"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# copy user guide
	Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs" `
	| Where-Object { ($_.Name -like "USER-GUIDES*.pdf") } `
	| ForEach-Object { $__source = $_.FullName
		$__dest = "${_workspace}\$(FS-Get-File "${__source}")"
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
		$__dest = "${_workspace}\$(FS-Get-File "${__source}")"
		$null = I18N-Assemble "${__source}" "${__dest}"
		$___process = FS-Copy-File "${__source}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Assemble-Failed
			return 1
		}
	}


	# assemble icon.png
	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\icons\icon-128x128.png"
	$__dest = "${_workspace}\icon.png"
	$null = I18N-Assemble "${__source}" "${__dest}"
	$___process = FS-Copy-File "${__source}" "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Assemble-Failed
		return 1
	}


	# begin packaging
	$__current_path = Get-Location
	$null = Set-Location -Path "${_workspace}"

	## package tar.xz
	$__dest = "lib${env:PROJECT_SKU}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}.tar.xz"
	$null = I18N-Create-Package "${__dest}"
	$__dest = "${_directory}\${__dest}"
	$___process = TAR-Create-XZ "${__dest}" "."
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		$null = Set-Location -Path "${__current_path}"
		$null = Remove-Variable -Name __current_path
		return 1
	}

	## package zip
	$__dest = "lib${env:PROJECT_SKU}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}.zip"
	$null = I18N-Create-Package "${__dest}"
	$__dest = "${_directory}\${__dest}"
	$___process = ZIP-Create "${__dest}" "."
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		$null = Set-Location -Path "${__current_path}"
		$null = Remove-Variable -Name __current_path
		return 1
	}

	## package nupkg
	$__acceptance = "false"
	if ($(STRINGS-To-Lowercase "${env:PROJECT_LICENSE_ACCEPTANCE_REQUIRED}") -eq "true") {
		$__acceptance = "true"
	}

	$__dest = "lib${env:PROJECT_SKU}.nuspec"
	$null = I18N-Create "${__dest}"
	$__dest = ".\${__dest}"
	$___process = FS-Write-File "${__dest}" @"
<?xml version='1.0' encoding='utf-8'?>
<package xmlns='http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd'>
	<metadata>
		<id>${env:PROJECT_SKU}</id>
		<version>${env:PROJECT_VERSION}</version>
		<authors>${env:PROJECT_CONTACT_NAME}</authors>
		<owners>${env:PROJECT_CONTACT_NAME}</owners>
		<projectUrl>${env:PROJECT_SOURCE_URL}</projectUrl>
		<title>${env:PROJECT_NAME}</title>
		<description>${env:PROJECT_PITCH}</description>
		<license>${env:PROJECT_LICENSE}</license>
		<requireLicenseAcceptance>${__acceptance}</requireLicenseAcceptance>
		<readme>${env:PROJECT_README}</readme>
	</metadata>
	<files>
		<file src="${env:PROJECT_README}" target="${env:PROJECT_README}" />
		<file src="icon.png" target="icon.png" />
		<file src="lib\**" target="lib" />
	</files>
</package>

"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		$null = Set-Location -Path "${__current_path}"
		$null = Remove-Variable -Name __current_path
		return 1
	}

	$__dest = "lib${env:PROJECT_SKU}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}.nupkg"
	$null = I18N-Create-Package "${__dest}"
	$__dest = "${_directory}\${__dest}"
	$___process = ZIP-Create "${__dest}" "."
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		$null = Set-Location -Path "${__current_path}"
		$null = Remove-Variable -Name __current_path
		return 1
	}

	## done - clean up
	$null = Set-Location -Path "${__current_path}"
	$null = Remove-Variable -Name __current_path


	# report status
	return 0
}
