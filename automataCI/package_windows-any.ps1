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




# (0) initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
        Write-Error "[ ERROR ] - Please run me from ci.cmd instead!\n"
        exit 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_package-changelog_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_package-archive_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_package-deb_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_package-rpm_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_package-flatpak_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_package-pypi_windows-any.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\_package-docker_windows-any.ps1"




# (1) source locally provided functions
$DEST = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}"
$DEST = "${DEST}\package_windows-any.ps1"
OS-Print-Status info "sourcing content assembling functions from: ${DEST}"
$__process = FS-Is-Target-Exist "${DEST}"
if ($__process -ne 0) {
	OS-Print-Status error "Source failed."
	exit 1
}
. "${DEST}"




# (2) 1-time setup job required materials
$DEST = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
OS-Print-Status info "remaking package directory: $DEST"
$__process = FS-Remake-Directory $DEST
if ($__process -ne 0) {
	OS-Print-Status error "remake failed."
	exit 1
}


$FILE_CHANGELOG_MD = "${env:PROJECT_PATH_ROOT}\MARKDOWN.md"
$FILE_CHANGELOG_DEB = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb\changelog.gz"
$__process = Package-Run-Changelog "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if ($__process -ne 0) {
	exit 1
}




# (3) begin packaging
foreach ($i in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}")) {
	$i = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${i}"
	$__process = FS-Is-Directory "$i"
	if ($__process -eq 0) {
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

	$__process = PACKAGE-Run-Archive `
		"$DEST" `
		"$i" `
		"$TARGET_FILENAME" `
		"$TARGET_OS" `
		"$TARGET_ARCH"
	if ($__process -ne 0) {
		exit 1
	}

	$__process = PACKAGE-Run-DEB `
		"$DEST" `
		"$i" `
		"$TARGET_FILENAME" `
		"$TARGET_OS" `
		"$TARGET_ARCH" `
		"$FILE_CHANGELOG_DEB"
	if ($__process -ne 0) {
		exit 1
	}

	$__process = PACKAGE-Run-RPM `
		"$DEST" `
		"$i" `
		"$TARGET_FILENAME" `
		"$TARGET_OS" `
		"$TARGET_ARCH"
	if ($__process -ne 0) {
		exit 1
	}

	$__process = PACKAGE-Run-FLATPAK `
		"$DEST" `
		"$i" `
		"$TARGET_FILENAME" `
		"$TARGET_OS" `
		"$TARGET_ARCH"
	if ($__process -ne 0) {
		exit 1
	}

	$__process = PACKAGE-Run-PYPI `
		"$DEST" `
		"$i" `
		"$TARGET_FILENAME" `
		"$TARGET_OS" `
		"$TARGET_ARCH"
	if ($__process -ne 0) {
		exit 1
	}

	$__process = PACKAGE-Run-DOCKER `
		"$DEST" `
		"$i" `
		"$TARGET_FILENAME" `
		"$TARGET_OS" `
		"$TARGET_ARCH"
	if ($__process -ne 0) {
		exit 1
	}

	# report task verdict
	OS-Print-Status success ""
}

exit 0
