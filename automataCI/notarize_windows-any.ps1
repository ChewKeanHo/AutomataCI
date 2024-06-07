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
	Write-Error "[ ERROR ] - Please run me from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




# source locally provided functions
$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\${env:PROJECT_PATH_CI}"
$__recipe = "${__recipe}\notarize_windows-any.ps1"
$___process = FS-Is-File "${__recipe}"
if ($___process -eq 0) {
	$null = I18N-Run "${__recipe}"
	$___process = . "${__recipe}"
	if ($___process -ne 0) {
		$null = I18N-Run-Failed
		return 1
	}
}




# begin notarize
$___process = FS-Is-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
if ($___process -ne 0) {
	# nothing build - bailing
	return 0
}

foreach ($i in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}")) {
	$___process = FS-Is-File "$i"
	if ($___process -ne 0) {
		continue
	}


	# parse build candidate
	$null = I18N-Detected "$i"
	$TARGET_FILENAME = FS-Get-File "$i"
	$TARGET_FILENAME = FS-Extension-Remove "$TARGET_FILENAME"
	$TARGET_OS = $TARGET_FILENAME -replace ".*_"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "_.*"
	$TARGET_ARCH = $TARGET_OS -replace ".*-"
	$TARGET_OS = $TARGET_OS -replace "-.*"

	if (($(STRINGS-Is-Empty "$TARGET_OS") -eq 0) -or
		($(STRINGS-Is-Empty "$TARGET_ARCH") -eq 0) -or
		($(STRINGS-Is-Empty "$TARGET_FILENAME") -eq 0)) {
		$null = I18N-File-Has-Bad-Stat-Skipped
		continue
	}

	$___process = STRINGS-Has-Prefix "${env:PROJECT_SKU}" "${TARGET_FILENAME}"
	if ($___process -ne 0) {
		$null = I18N-Is-Incompatible-Skipped "${TARGET_FILENAME}"
		continue
	}

	$cmd = "NOTARIZE-Certify"
	$null = I18N-Check-Availability "$cmd"
	$___process = OS-Is-Command-Available "$cmd"
	if ($___process -ne 0) {
		$null = I18N-Check-Failed
		continue
	}

	$___process = NOTARIZE-Certify "$i" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}" `
		"${TARGET_FILENAME}" `
		"${TARGET_OS}" `
		"${TARGET_ARCH}"
	switch ($___process) {
	12 {
		$null = I18N-Simulate-Notarize
	} 11 {
		$null = I18N-Notarize-Unavailable
	} 10 {
		$null = I18N-Notarize-Not-Applicable
	} 0 {
		$null = I18N-Run-Successful
	} default {
		$null = I18N-Notarize-Failed
		return 1
	}}
}




# report status
return 0
