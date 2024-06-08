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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\node.ps1"




# define build variables
$__workspace_path = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\build-${env:PROJECT_SKU}_js-js"
$__placeholders = @(
)




# execute
$null = I18N-Activate-Environment
$___process = NODE-Activate-Local-Environment
if ($___process -ne 0) {
	$null = I18N-Activate-Failed
	return 1
}


## build the artifacts and shift it to the workspace
$null = I18N-Build "${env:PROJECT_NODE}"
$null = FS-Remove-Silently "${__workspace_path}"
$null = FS-Make-Housing-Directory "${__workspace_path}"

$__current_path = Get-Location
$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NODE}"
$___process = NODE-NPM-Run "build"
$null = Set-Location "${__current_path}"
$null = Remove-Variable __current_path
if ($___process -ne 0) {
	$null = I18N-Build-Failed
	return 1
}

$___source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NODE}\dist\build"
$___process = FS-Move "${___source}" "${__workspace_path}"
if ($___process -ne 0) {
	$null = I18N-Build-Failed
	return 1
}

$___dest = "${__workspace_path}\package.json"
foreach ($___line in (Get-Content "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NODE}\package.json")) {
	## overrides name
	$___key = '  "name": '
	if ($(STRINGS-Is-Empty "$($___line -replace "^${___key}.*$")") -eq 0) {
		$___value = "$(STRINGS-To-Lowercase "@${env:PROJECT_SCOPE}/${env:PROJECT_SKU}")"
		$___process = FS-Append-File "${___dest}" "${___key}`"${___value}`",`n"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed
			return 1
		}

		continue
	}

	## overrides version
	$___key = '  "version": '
	if ($(STRINGS-Is-Empty "$($___line -replace "^${___key}.*$")") -eq 0) {
		$___process = FS-Append-File "${___dest}" "${___key}`"${env:PROJECT_VERSION}`",`n"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed
			return 1
		}

		continue
	}

	## overrides description
	$___key = '  "description": '
	if ($(STRINGS-Is-Empty "$($___line -replace "^${___key}.*$")") -eq 0) {
		$___process = FS-Append-File "${___dest}" "${___key}`"${env:PROJECT_PITCH}`",`n"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed
			return 1
		}

		continue
	}

	## overrides author
	$___key = '  "author": '
	if ($(STRINGS-Is-Empty "$($___line -replace "^${___key}.*$")") -eq 0) {
		$___process = FS-Append-File "${___dest}" "${___key}`"${env:PROJECT_CONTACT_NAME}`",`n"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed
			return 1
		}

		continue
	}

	## overrides license
	$___key = '  "license": '
	if ($(STRINGS-Is-Empty "$($___line -replace "^${___key}.*$")") -eq 0) {
		$___process = FS-Append-File "${___dest}" "${___key}`"${env:PROJECT_LICENSE}`",`n"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed
			return 1
		}

		continue
	}

	## overrides homepage
	$___key = '  "homepage": '
	if ($(STRINGS-Is-Empty "$($___line -replace "^${___key}.*$")") -eq 0) {
		$___process = FS-Append-File "${___dest}" "${___key}`"${env:PROJECT_CONTACT_WEBSITE}`",`n"
		if ($___process -ne 0) {
			$null = I18N-Build-Failed
			return 1
		}

		continue
	}

	## retain
	$___process = FS-Append-File "${___dest}" "${___line}`n"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed
		return 1
	}
}

## assemble other assets and npm metadata files
$null = I18N-Assemble-Package
$___process = FS-Copy-File `
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_README}" `
	"${__workspace_path}\README.md"
if ($___process -ne 0) {
	$null = I18N-Assemble-Failed
	return 1
}

$___process = FS-Copy-File `
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_LICENSE_FILE}" `
	"${__workspace_path}\LICENSE.txt"
if ($___process -ne 0) {
	$null = I18N-Assemble-Failed
	return 1
}

## export npm tarball
### IMPORTANT: npm only recognizes .tgz file extension so rename it accordingly.
###            Also, keep the lib- prefix -NPM for CI identification purposes.
$___dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\lib${env:PROJECT_SKU}-NPM_js-js.tgz"
$null = I18N-Export "${___dest}"
$null = FS-Make-Housing-Directory "${___dest}"
$null = FS-Remove-Silently "${___dest}"

$__current_path = Get-Location
$null = Set-Location "${__workspace_path}"
$___process = TAR-Create-GZ "${___dest}" "."
$null = Set-Location "${__current_path}"
$null = Remove-Variable __current_path
if ($___process -ne 0) {
	$null = I18N-Export-Failed
	return 1
}




# placeholding flag files
foreach ($__line in $__placeholders) {
	if ($(STRINGS-Is-Empty "${__line}") -eq 0) {
		continue
	}


	# build the file
	$__file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${__line}"
	$null = I18N-Build "${__line}"
	$null = FS-Remove-Silently "${__file}"
	$___process = FS-Touch-File "${__file}"
	if ($___process -ne 0) {
		$null = I18N-Build-Failed
		return 1
	}
}




# compose documentations




# report status
return 0
