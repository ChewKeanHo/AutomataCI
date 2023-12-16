# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run me from ci.cmd instead!\n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\sync.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-sync.ps1"

. "${env:LIBS_AUTOMATACI}\_package-changelog_windows-any.ps1"




# 1-time setup job required materials
$DEST = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
$null = I18N-Status-Print-Package-Directory-Remake "$DEST"
$__process = FS-Remake-Directory $DEST
if ($__process -ne 0) {
	$null = I18N-Status-Print-Package-Remake-Failed
	return 1
}


$FILE_CHANGELOG_MD = "${env:PROJECT_SKU}-CHANGELOG_${env:PROJECT_VERSION}.md"
$FILE_CHANGELOG_MD = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${FILE_CHANGELOG_MD}"
$FILE_CHANGELOG_DEB = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb\changelog.gz"
$__process = Package-Run-CHANGELOG "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if ($__process -ne 0) {
	exit 1
}


$null = I18N-Status-Print-Newline




# prepare for parallel package
$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\packagers"
$null = I18N-Status-Print-Package-Directory-Log-Remake "${__log_directory}"
$null = FS-Remake-Directory "${__log_directory}"
if (-not (Test-Path -PathType Container -Path "${__log_directory}")) {
	$null = I18N-Status-Print-Package-Remake-Failed
	return 1
}


$__control_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\packagers-parallel"
$null = I18N-Status-Print-Package-Directory-Control-Remake "${__control_directory}"
$null = FS-Remake-Directory "${__control_directory}"
if (-not (Test-Path -PathType Container -Path "${__control_directory}")) {
	$null = I18N-Status-Print-Package-Remake-Failed
	return 1
}


$__parallel_control = "${__control_directory}\control-parallel.txt"
$null = FS-Remove-Silently "${__parallel_control}"


$__series_control = "${__control_directory}\control-series.txt"
$null = FS-Remove-Silently "${__series_control}"


function SUBROUTINE-Package {
	param(
		[string]$__line
	)


	# initialize libraries from scratch
	$null = . "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"

	$null = . "${env:LIBS_AUTOMATACI}\services\i18n\status-job-package.ps1"

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
	$null = I18N-Status-Print-Package-Exec "${__subject}"
	$null = FS-Remove-Silently "${__log}"

	try {
		${function:SUBROUTINE-Exec} = Get-Command `
			"${__command}" `
			-ErrorAction SilentlyContinue
		$($__process = SUBROUTINE-Exec "${__arguments}") *> "${__log}"
	} catch {
		$__process = 1
	}
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Package-Exec-Failed "${__subject}"
		return 1
	}


	# report status
	return 0
}




# begin registering packagers
foreach ($file in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}" `
			| Select-Object -ExpandProperty FullName)) {
	$__process = FS-Is-File "$file"
	if ($__process -ne 0) {
		continue
	}


	# parse build candidate
	$null = I18N-Status-Print-File-Detected "$file"
	$TARGET_FILENAME = Split-Path -Leaf $file
	$TARGET_FILENAME = $TARGET_FILENAME -replace "\..*$"
	$TARGET_OS = $TARGET_FILENAME -replace ".*_"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "_.*"
	$TARGET_ARCH = $TARGET_OS -replace ".*-"
	$TARGET_OS = $TARGET_OS -replace "-.*"

	if (($(STRINGS-Is-Empty "${TARGET_OS}") -eq 0) -or
		($(STRINGS-Is-Empty "${TARGET_ARCH}") -eq 0) -or
		($(STRINGS-Is-Empty "${TARGET_FILENAME}") -eq 0)) {
		$null = I18N-Status-Print-File-Bad-Stat-Skipped
		continue
	}

	$__process = STRINGS-Has-Prefix "${env:PROJECT_SKU}" "${TARGET_FILENAME}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-File-Incompatible-Skipped
		continue
	}

	$null = I18N-Status-Print-Sync-Register "$file"
	$__common = "${DEST}|${file}|${TARGET_FILENAME}|${TARGET_OS}|${TARGET_ARCH}"

	$__log = "${__log_directory}\archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-ARCHIVE
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\cargo_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-CARGO
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\chocolatey_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-Chocolatey
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\deb_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${FILE_CHANGELOG_DEB}|${__log}|PACKAGE-Run-DEB
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\docker_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__series_control}" @"
${__common}|${__log}|PACKAGE-Run-DOCKER
"@
	if ($__process -ne 0) {
		return 1
	}

	$__flatpak_path = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${env:PROJECT_PATH_RELEASE}\flatpak"
	$__log = "${__log_directory}\flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__series_control}" @"
${__common}|${__flatpak_path}|${__log}|PACKAGE-Run-FLATPAK
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\homebrew_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-Homebrew
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\ipk_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-IPK
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\msi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__series_control}" @"
${__common}|${__log}|PACKAGE-Run-MSI
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\pypi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-PYPI
"@
	if ($__process -ne 0) {
		return 1
	}

	$__log = "${__log_directory}\rpm_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-RPM
"@
	if ($__process -ne 0) {
		return 1
	}
}


$null = I18N-Status-Print-Sync-Exec-Parallel
if (Test-Path "${__parallel_control}") {
	$__process = SYNC-Parallel-Exec `
		${function:SUBROUTINE-Package}.ToString() `
		"${__parallel_control}" `
		"${__control_directory}" `
		"$([System.Environment]::ProcessorCount)"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Sync-Exec-Failed
		return 1
	}
}


$null = I18N-Status-Print-Sync-Exec-Series
if (Test-Path "${__series_control}") {
	$__process = SYNC-Series-Exec `
		${function:SUBROUTINE-Package}.ToString() `
		"${__series_control}"
	if ($__process -ne 0) {
		$null = I18N-Status-Print-Sync-Exec-Failed
		return 1
	}
}




# report status
$null = I18N-Status-Print-Run-Successful
return 0
