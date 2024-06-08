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
	## copy over known archived files
	if ($(FS-Is-Target-A-NPM "${_target}") -eq 0) {
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
		$__dest = "lib${env:PROJECT_SKU}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}.tar.gz"
		$__dest = "${_directory}\${__dest}"
		$null = I18N-Copy "${_target}" "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Copy-Failed
			return 1
		}

		return 0
	} elseif ($(FS-Is-Target-A-TARXZ "${_target}") -eq 0) {
		$__dest = "lib${env:PROJECT_SKU}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}.tar.xz"
		$__dest = "${_directory}\${__dest}"
		$null = I18N-Copy "${_target}" "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Copy-Failed
			return 1
		}

		return 0
	} elseif ($(FS-Is-Target-A-ZIP "${_target}") -eq 0) {
		$__dest = "lib${env:PROJECT_SKU}_${env:PROJECT_VERSION}_${_target_os}-${_target_arch}.zip"
		$__dest = "${_directory}\${__dest}"
		$null = I18N-Copy "${_target}" "${__dest}"
		$___process = FS-Copy-File "${_target}" "${__dest}"
		if ($___process -ne 0) {
			$null = I18N-Copy-Failed
			return 1
		}

		return 0
	}

	## assume standalone library file - manually package into .tar.xz, .zip, and .nupkg
	$__workspace = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\package-${_target_name}"
	$null = FS-Remake-Directory "${__workspace}"

	$null = I18N-Copy "${_target}" "${__workspace}"
	$___process = FS-Copy-File "${_target}" "${__workspace}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}

	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_README}"
	$null = I18N-Copy "${__source}" "${__workspace}"
	$___process = FS-Copy-File "${__source}" "${__workspace}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}

	$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_LICENSE_FILE}"
	$null = I18N-Copy "${__source}" "${__workspace}"
	$___process = FS-Copy-File "${__source}" "${__workspace}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}

	$__current_path = Get-Location
	$null = Set-Location -Path "${__workspace}"
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
	$__dest = ".\Package.nuspec"
	$__acceptance = "false"
	if ($(STRINGS-To-Lowercase "${env:PROJECT_LICENSE_ACCEPTANCE_REQUIRED}") -eq "true") {
		$__acceptance = "true"
	}

	$null = I18N-Create "${__dest}"
	$___process = FS-Write-File "${__dest}" @"
<?xml version='1.0' encoding='utf-8'?>
<package xmlns='http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd'>
	<metadata>
		<id>${PROJECT_SKU}</id>
		<version>${PROJECT_VERSION}</version>
		<authors>${PROJECT_CONTACT_NAME}</authors>
		<owners>${PROJECT_CONTACT_NAME}</owners>
		<projectUrl>${PROJECT_SOURCE_URL}</projectUrl>
		<title>${PROJECT_NAME}</title>
		<description>${PROJECT_PITCH}</description>
		<license>${PROJECT_LICENSE}</license>
		<requireLicenseAcceptance>${__acceptance}</requireLicenseAcceptance>
		<readme>${PROJECT_README}</readme>
	</metadata>
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
