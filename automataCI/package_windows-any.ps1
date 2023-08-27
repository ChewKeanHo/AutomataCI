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
        Write-Error "[ ERROR ] - Please source from ci.cmd instead!\n"
        exit 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\tar.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\zip.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\deb.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\changelog.ps1"




# (1) safety checking control surfaces
OS-Print-Status info "checking tar functions availability..."
$process = TAR-Is-Available
if ($process -ne 0) {
	OS-Print-Status error "check failed."
	exit 1
}

OS-Print-Status info "checking changelog functions availability..."
$process = CHANGELOG-Is-Available
if ($process -ne 0) {
	OS-Print-Status error "check failed."
	exit 1
}

OS-Print-Status info "sourcing content assembling functions from the project..."
$recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\${env:PROJECT_PATH_CI}"
$recipe = "${recipe}\package_windows-any.ps1"
$process = FS-IsExists $recipe
if (-not ($process)) {
	OS-Print-Status error "sourcing failed - Missing file: ${recipe}"
	exit 1
}
. $recipe




# (2) clean up destination path
$dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
OS-Print-Status info "remaking package directory: $dest"
$process = FS-Remake-Directory $dest
if ($process -ne 0) {
	OS-Print-Status error "remake failed."
	exit 1
}




# (3) validate changelog
OS-Print-Status info "validating ${env:PROJECT_VERSION} data changelog entry..."
$process = CHANGELOG-Compatible-Data-Version `
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
	"${env:PROJECT_VERSION}"
if ($process -ne 0) {
	OS-Print-Status error "validation failed - there is an existing entry."
	exit 1
}


OS-Print-Status info "validating ${env:PROJECT_VERSION} deb changelog entry..."
$process = CHANGELOG-Compatible-Deb-Version `
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
	"${env:PROJECT_VERSION}"
if ($process -ne 0) {
	OS-Print-Status error "validation failed - there is an existing entry."
	exit 1
}




# (4) assemble changelog
OS-Print-Status info "assembling markdown changelog..."
$FILE_CHANGELOG_MD="${env:PROJECT_PATH_ROOT}\MARKDOWN.md"
$process = CHANGELOG-Assemble-MD `
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
	"$FILE_CHANGELOG_MD" `
	"$env:PROJECT_VERSION"
if ($process -ne 0) {
	OS-Print-Status error "assembly failed."
	exit 1
}


OS-Print-Status info "assembling deb changelog..."
$FILE_CHANGELOG_DEB="${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb\changelog"
$process = CHANGELOG-Assemble-DEB `
	"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
	"$FILE_CHANGELOG_DEB" `
	"$env:PROJECT_VERSION"
if ($process -ne 0) {
	OS-Print-Status error "assembly failed."
	exit 1
}
$FILE_CHANGELOG_DEB="${FILE_CHANGELOG_DEB}.gz"




# (5) begin packaging
foreach ($i in Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}") {
	if (FS-IsDirectory $i) {
		continue
	}
	OS-Print-Status info "detected ${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${i}"


	# (5.1) parse build candidate
	$TARGET_FILENAME = Split-Path -Leaf $i
	$TARGET_FILENAME = $TARGET_FILENAME -replace `
				".*${PROJECT_PATH_ROOT}\${PROJECT_PATH_BUILD}\"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "\..*$"
	$TARGET_OS = $TARGET_FILENAME -replace ".*_"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "_.*"
	$TARGET_ARCH = $TARGET_OS -replace ".*-"
	$TARGET_OS = $TARGET_OS -replace "-.*"

	if (-not $TARGET_OS -or -not $TARGET_ARCH -or -not $TARGET_FILENAME) {
		OS-Print-Status warning "detected $i but failed to parse. Skipping."
		continue
	}

	$TARGET_SKU = "$env:PROJECT_SKU"
	if ($TARGET_FILENAME -ne $TARGET_SKU) {
		$TARGET_SKU = "${env:PROJECT_SKU}-src"
		OS-Print-Status warning "incompatible file. Skipping."
		continue
	}


	# (5.2) archive into tar.xz / zip package
	$src = "archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
	$src = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${src}"
	$dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
	OS-Print-Status info "archiving ${src} for ${TARGET_OS}-${TARGET_ARCH}"
	OS-Print-Status info "remaking workspace directory ${src}"
	$process = FS-Remake-Directory $src
	if ($process -ne 0) {
		OS-Print-Status error "remake failed."
		exit 1
	}

	# (5.2.1) copy necessary complimentary files to the package
	$process = Get-Command -Name "PACKAGE-Assemble-Archive-Content" `
				-ErrorAction SilentlyContinue
	if (-not ($process)) {
		OS-Print-Status error "missing PACKAGE-Assemble-Archive-Content function."
		exit 1
	}

	OS-Print-Status info "assembling package files..."
	$process = PACKAGE-Assemble-Archive-Content `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}\${i}" `
			"$src" `
			"$TARGET_NAME" `
			"$TARGET_OS" `
			"$TARGET_ARCH"
	if (-not ($process)) {
		OS-Print-Status error "assembling failed."
		exit 1
	}

	# (5.2.2) archive the assembly payload
	switch ($TARGET_OS) {
	"windows" {
		$dest = "${dest}\${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.zip"
		OS-Print-Status info "packaging ${dest}.zip"
		$process = ZIP-Create -Source $src -Destination $dest
		if ($process -ne 0) {
			OS-Print-Status error "packaging failed."
			exit 1
		}
	} default {
		$dest = "${dest}\${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}"
		OS-Print-Status info "packaging $dest.tar.xz"
		7ZIP-Create-TARXZ -Source $src -Destination $dest
		if ($process -ne 0) {
			OS-Print-Status error "packaging failed."
			exit 1
		}
	}}

	# (5.3) archive debian .deb
	$process = DEB-Is-Available $TARGET_OS $TARGET_ARCH
	if ($process -eq 0) {
		Write-Host "placeholder deb build."
	} else {
		OS-Print-Status warning "DEB is incompatible or not available. Skipping."
	}

	# (5.4) report task verdict
	OS-Print-Status success ""
}
exit 0
