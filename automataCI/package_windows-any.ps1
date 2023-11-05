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

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\sync.ps1"

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_package-changelog_windows-any.ps1"




# 1-time setup job required materials
$DEST = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
OS-Print-Status info "remaking package directory: $DEST"
$__process = FS-Remake-Directory $DEST
if ($__process -ne 0) {
	OS-Print-Status error "remake failed."
	return 1
}


$FILE_CHANGELOG_MD = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\CHANGELOG.md"
$FILE_CHANGELOG_DEB = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb\changelog.gz"
$__process = Package-Run-Changelog "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if ($__process -ne 0) {
	exit 1
}


OS-Print-Status plain ""




# prepare for parallel package
$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\packagers"
OS-Print-Status info "remaking packagers' log directory: ${__log_directory}"
$null = FS-Remake-Directory "${__log_directory}"
if (-not (Test-Path -PathType Container -Path "${__log_directory}")) {
	OS-Print-Status error "make failed."
	return 1
}


$__control_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\packagers-parallel"
OS-Print-Status info "remaking packagers' control directory: ${__control_directory}"
$null = FS-Remake-Directory "${__control_directory}"
if (-not (Test-Path -PathType Container -Path "${__control_directory}")) {
	OS-Print-Status error "make failed."
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


	# parse input
	$__command = $__line.Split("|")[-1]
	$__log = $__line.Split("|")[-2]
	$__arguments = $__line.Split("|")
	$__arguments = $__arguments[0..$($__arguments.Length - 3)]
	$__arguments = $__arguments -Join "|"

	$__subject = Split-Path -Leaf -Path "${__log}"
	$__subject = [IO.Path]::ChangeExtension("${__subject}", '').TrimEnd('.')


	# initialize libraries from scratch
	$libs = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}"
	$null = . "${libs}\services\io\os.ps1"
	$null = . "${libs}\services\io\fs.ps1"
	$null = . "${libs}\services\io\strings.ps1"
	$null = . "${libs}\_package-archive_windows-any.ps1"
	$null = . "${libs}\_package-cargo_windows-any.ps1"
	$null = . "${libs}\_package-changelog_windows-any.ps1"
	$null = . "${libs}\_package-chocolatey_windows-any.ps1"
	$null = . "${libs}\_package-deb_windows-any.ps1"
	$null = . "${libs}\_package-docker_windows-any.ps1"
	$null = . "${libs}\_package-flatpak_windows-any.ps1"
	$null = . "${libs}\_package-homebrew_windows-any.ps1"
	$null = . "${libs}\_package-ipk_windows-any.ps1"
	$null = . "${libs}\_package-pypi_windows-any.ps1"
	$null = . "${libs}\_package-rpm_windows-any.ps1"
	$null = . "${libs}\_package-sourcing_windows-any.ps1"


	# execute
	OS-Print-Status info "packaging ${__subject}..."

	$null = FS-Remove-Silently "${__log}"

	try {
		${function:SUBROUTINE-Exec} = Get-Command "${__command}" `
			-ErrorAction SilentlyContinue
		SUBROUTINE-Exec "${__arguments}" -OutVariable __process *>${__log}
	} catch {
		$__process = 1
	}

	if ($__process -ne 0) {
		OS-Print-Status error "package failed - ${__subject}"
		return 1
	}


	# report status
	return 0
}




# begin registering packagers
foreach ($i in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}")) {
	$i = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${i}"
	$__process = FS-Is-Directory "$i"
	if ($__process -eq 0) {
		continue
	}

	$__process = FS-Is-File "$i"
	if ($__process -ne 0) {
		continue
	}


	# parse build candidate
	OS-Print-Status info "detected $i"
	$TARGET_FILENAME = Split-Path -Leaf $i
	$TARGET_FILENAME = $TARGET_FILENAME -replace `
		(Join-Path $env:PROJECT_PATH_ROOT $env:PROJECT_PATH_BUILD), ""
	$TARGET_FILENAME = $TARGET_FILENAME -replace "\..*$"
	$TARGET_OS = $TARGET_FILENAME -replace ".*_"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "_.*"
	$TARGET_ARCH = $TARGET_OS -replace ".*-"
	$TARGET_OS = $TARGET_OS -replace "-.*"

	if ([string]::IsNullOrEmpty($TARGET_OS) -or
		[string]::IsNullOrEmpty($TARGET_ARCH) -or
		[string]::IsNullOrEmpty($TARGET_FILENAME)) {
		OS-Print-Status warning "failed to parse file. Skipping."
		continue
	}

	$__process = STRINGS-Has-Prefix "${env:PROJECT_SKU}" "$TARGET_FILENAME"
	if ($__process -ne 0) {
		OS-Print-Status warning "incompatible file. Skipping."
		continue
	}

	OS-Print-Status info "registering $i"
	$__common = "${DEST}|${i}|${TARGET_FILENAME}|${TARGET_OS}|${TARGET_ARCH}"

	$__log = "${__log_directory}\archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-Archive
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

	$__log = "${__log_directory}\homebrew_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-Homebrew
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

	$__log = "${__log_directory}\ipk_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-IPK
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

	$__flatpak_path = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${env:PROJECT_PATH_RELEASE}\flatpak"
	$__log = "${__log_directory}\flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__series_control}" @"
${__common}|${__flatpak_path}|${__log}|PACKAGE-Run-FLATPAK
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

	$__log = "${__log_directory}\cargo_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
	$__process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-Cargo
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
}


OS-Print-Status plain ""
OS-Print-Status info "executing all parallel runs..."
$__process = SYNC-Parallel-Exec `
	${function:SUBROUTINE-Package}.ToString() `
	"${__parallel_control}" `
	"${__control_directory}" `
	"$([System.Environment]::ProcessorCount)"
if ($__process -ne 0) {
	return 1
}


OS-Print-Status plain ""
OS-Print-Status info "executing all series runs..."
$__process = SYNC-Series-Exec ${function:SUBROUTINE-Package}.ToString() "${__series_control}"
if ($__process -ne 0) {
	return 1
}




# report status
OS-Print-Status success "`n"
return 0
