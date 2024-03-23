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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return
}




# execute
## IMPORTANT NOTE:
##   (1) Appearently, PowerShell disallowed globally scoped dot import inside
##       a function. Hence, we don't have a choice but to do repetition.
if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_SOURCE}") -ne 0) {
	$package_fx = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}"
	$package_fx = "${package_fx}\${env:PROJECT_PATH_CI}\package_windows-any.ps1"
	if ($(FS-Is-File "$package_fx") -eq 0) {
		$null = I18N-Source "${package_fx}"

		$___process = . $package_fx
		if ($___process -ne 0) {
			$null = I18N-Source-Failed
			return 1
		}
	}
}

if ($(STRINGS-Is-Empty "${env:PROJECT_ANGULAR}") -ne 0) {
	$package_fx = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_ANGULAR}"
	$package_fx = "${package_fx}\${env:PROJECT_PATH_CI}\package_windows-any.ps1"
	if ($(FS-Is-File "$package_fx") -eq 0) {
		$null = I18N-Source "${package_fx}"

		$___process = . $package_fx
		if ($___process -ne 0) {
			$null = I18N-Source-Failed
			return 1
		}
	}
}

if ($(STRINGS-Is-Empty "${env:PROJECT_C}") -ne 0) {
	$package_fx = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_C}"
	$package_fx = "${package_fx}\${env:PROJECT_PATH_CI}\package_windows-any.ps1"
	if ($(FS-Is-File "$package_fx") -eq 0) {
		$null = I18N-Source "${package_fx}"

		$___process = . $package_fx
		if ($___process -ne 0) {
			$null = I18N-Source-Failed
			return 1
		}
	}
}

if ($(STRINGS-Is-Empty "${env:PROJECT_GO}") -ne 0) {
	$package_fx = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_GO}"
	$package_fx = "${package_fx}\${env:PROJECT_PATH_CI}\package_windows-any.ps1"
	if ($(FS-Is-File "$package_fx") -eq 0) {
		$null = I18N-Source "${package_fx}"

		$___process = . $package_fx
		if ($___process -ne 0) {
			$null = I18N-Source-Failed
			return 1
		}
	}
}

if ($(STRINGS-Is-Empty "${env:PROJECT_NIM}") -ne 0) {
	$package_fx = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}"
	$package_fx = "${package_fx}\${env:PROJECT_PATH_CI}\package_windows-any.ps1"
	if ($(FS-Is-File "$package_fx") -eq 0) {
		$null = I18N-Source "${package_fx}"

		$___process = . $package_fx
		if ($___process -ne 0) {
			$null = I18N-Source-Failed
			return 1
		}
	}
}

if ($(STRINGS-Is-Empty "${env:PROJECT_PYTHON}") -ne 0) {
	$package_fx = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}"
	$package_fx = "${package_fx}\${env:PROJECT_PATH_CI}\package_windows-any.ps1"
	if ($(FS-Is-File "$package_fx") -eq 0) {
		$null = I18N-Source "${package_fx}"

		$___process = . $package_fx
		if ($___process -ne 0) {
			$null = I18N-Source-Failed
			return 1
		}
	}
}

if ($(STRINGS-Is-Empty "${env:PROJECT_RESEARCH}") -ne 0) {
	$package_fx = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RESEARCH}"
	$package_fx = "${package_fx}\${env:PROJECT_PATH_CI}\package_windows-any.ps1"
	if ($(FS-Is-File "$package_fx") -eq 0) {
		$null = I18N-Source "${package_fx}"

		$___process = . $package_fx
		if ($___process -ne 0) {
			$null = I18N-Source-Failed
			return 1
		}
	}
}

if ($(STRINGS-Is-Empty "${env:PROJECT_RUST}") -ne 0) {
	$package_fx = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_RUST}"
	$package_fx = "${package_fx}\${env:PROJECT_PATH_CI}\package_windows-any.ps1"
	if ($(FS-Is-File "$package_fx") -eq 0) {
		$null = I18N-Source "${package_fx}"

		$___process = . $package_fx
		if ($___process -ne 0) {
			$null = I18N-Source-Failed
			return 1
		}
	}
}
