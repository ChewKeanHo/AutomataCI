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

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\sync.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"

. "${env:LIBS_AUTOMATACI}\_package-changelog_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_package-citation_windows-any.ps1"




# 1-time setup job required materials
$DEST = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
$null = I18N-Remake "${DEST}"
$___process = FS-Remake-Directory "${DEST}"
if ($___process -ne 0) {
	$null = I18N-Remake-Failed
	return 1
}


$FILE_CHANGELOG_MD = "${env:PROJECT_SKU}-CHANGELOG_${env:PROJECT_VERSION}.md"
$FILE_CHANGELOG_MD = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${FILE_CHANGELOG_MD}"
$FILE_CHANGELOG_DEB = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb\changelog.gz"
$___process = Package-Run-CHANGELOG "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if ($___process -ne 0) {
	return 1
}


$FILE_CITATION_CFF = "${env:PROJECT_SKU}-CITATION_${env:PROJECT_VERSION}.cff"
$FILE_CITATION_CFF = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${FILE_CITATION_CFF}"
$___process = Package-Run-CITATION "$FILE_CITATION_CFF"
if ($___process -ne 0) {
	return 1
}


$null = I18N-Newline




# prepare for parallel package
$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\packagers"
$null = I18N-Remake "${__log_directory}"
$null = FS-Remake-Directory "${__log_directory}"
$___process = FS-Is-Directory "${__log_directory}"
if ($___process -ne 0) {
	$null = I18N-Remake-Failed
	return 1
}


$__control_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\packagers-parallel"
$null = I18N-Remake "${__control_directory}"
$null = FS-Remake-Directory "${__control_directory}"
$___process = FS-Is-Directory "${__control_directory}"
if ($___process -ne 0) {
	$null = I18N-Remake-Failed
	return 1
}


$__parallel_control = "${__control_directory}\control-parallel.txt"
$null = FS-Remove-Silently "${__parallel_control}"


$__serial_control = "${__control_directory}\control-serial.txt"
$null = FS-Remove-Silently "${__serial_control}"


function SUBROUTINE-Package {
	param(
		[string]$__line
	)


	# initialize libraries from scratch
	$null = . "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"

	$null = . "${env:LIBS_AUTOMATACI}\_package-archive_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-cargo_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-changelog_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-chocolatey_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-deb_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-docker_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-flatpak_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-homebrew_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-ipk_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-msi_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-pypi_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-rpm_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-sourcing_windows-any.ps1"


	# parse input
	$__command = $__line.Split("|")[-1]
	$__log = $__line.Split("|")[-2]
	$__arguments = $__line.Split("|")
	$__arguments = $__arguments[0..$($__arguments.Length - 3)]
	$__arguments = $__arguments -Join "|"

	$__subject = Split-Path -Leaf -Path "${__log}"
	$__subject = FS-Extension-Remove "${__subject}" "*"


	# execute
	$null = I18N-Package "${__subject}"
	$null = FS-Remove-Silently "${__log}"

	try {
		${function:SUBROUTINE-Exec} = Get-Command `
			"${__command}" `
			-ErrorAction SilentlyContinue
		$($___process = SUBROUTINE-Exec "${__arguments}") *> "${__log}"
	} catch {
		$___process = 1
	}
	if ($___process -ne 0) {
		$null = I18N-Package-Failed
		return 1
	}


	# report status
	return 0
}




# begin registering packagers
if ($(FS-Is-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}") -eq 0) {
foreach ($file in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}" `
	| Select-Object -ExpandProperty FullName)) {
	$___process = FS-Is-File "$file"
	if ($___process -ne 0) {
		continue
	}


	# parse build candidate
	$null = I18N-Detected "${file}"
	$TARGET_FILENAME = Split-Path -Leaf $file
	$TARGET_FILENAME = $TARGET_FILENAME -replace "\..*$"
	$TARGET_OS = $TARGET_FILENAME -replace ".*_"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "_.*"
	$TARGET_ARCH = $TARGET_OS -replace ".*-"
	$TARGET_OS = $TARGET_OS -replace "-.*"

	if (($(STRINGS-Is-Empty "${TARGET_OS}") -eq 0) -or
		($(STRINGS-Is-Empty "${TARGET_ARCH}") -eq 0) -or
		($(STRINGS-Is-Empty "${TARGET_FILENAME}") -eq 0)) {
		$null = I18N-File-Has-Bad-Stat-Skipped
		continue
	}

	$___process = STRINGS-Has-Prefix "${env:PROJECT_SKU}" "${TARGET_FILENAME}"
	if ($___process -ne 0) {
		$___process = STRINGS-Has-Prefix "lib${env:PROJECT_SKU}" "${TARGET_FILENAME}"
		if ($___process -ne 0) {
			$null = I18N-Is-Incompatible-Skipped "${TARGET_FILENAME}"
			continue
		}
	}

	$null = I18N-Sync-Register "$file"
	$__common = "${DEST}|${file}|${TARGET_FILENAME}|${TARGET_OS}|${TARGET_ARCH}"

	$__log = "${__log_directory}\archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-ARCHIVE
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\cargo_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-CARGO
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\chocolatey_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-CHOCOLATEY
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\deb_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${FILE_CHANGELOG_DEB}|${__log}|PACKAGE-Run-DEB
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\docker_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__serial_control}" @"
${__common}|${__log}|PACKAGE-Run-DOCKER
"@
	if ($___process -ne 0) {
		return 1
	}

	$__flatpak_path = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${env:PROJECT_PATH_RELEASE}\flatpak"
	$__log = "${__log_directory}\flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__serial_control}" @"
${__common}|${__flatpak_path}|${__log}|PACKAGE-Run-FLATPAK
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\homebrew_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-HOMEBREW
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\ipk_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-IPK
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\msi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__serial_control}" @"
${__common}|${__log}|PACKAGE-Run-MSI
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\pypi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-PYPI
"@
	if ($___process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\rpm_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-RPM
"@
	if ($___process -ne 0) {
		return 1
	}
}
}


$null = I18N-Sync-Run
$___process = FS-Is-File "${__parallel_control}"
if ($___process -eq 0) {
	$___process = SYNC-Exec-Parallel `
		${function:SUBROUTINE-Package}.ToString() `
		"${__parallel_control}" `
		"${__control_directory}"
	if ($___process -ne 0) {
		$null = I18N-Sync-Failed
		return 1
	}
}


$null = I18N-Sync-Run-Series
$___process = FS-Is-File "${__serial_control}"
if ($___process -eq 0) {
	$___process = SYNC-Exec-Serial `
		${function:SUBROUTINE-Package}.ToString() `
		"${__serial_control}"
	if ($___process -ne 0) {
		$null = I18N-Sync-Failed
		return 1
	}
}




# report status
$null = I18N-Run-Successful
return 0
