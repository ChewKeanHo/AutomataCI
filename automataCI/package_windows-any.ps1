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


$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\io\os.ps1"
. $services

$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\io\fs.ps1"
. $services




# (1) execute tech specific CI jobs if available
$recipe = $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_SOURCE + "\" + $env:PROJECT_PATH_CI
$recipe = "$recipe\package_windows-any.ps1"
$process = FS-IsExists $recipe
if ($process) {
	. $recipe
	if ($?) {
		exit 0
	}
	exit 1
}




# (2) no custom job recipe. Use default job executions...
$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\archive\zip.ps1"
. $services

$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\archive\7zip.ps1"
. $services




# (3) safety checking control surfaces
$process = 7ZIP-Setup
if ($process -ne 0) {
	OS-Print-Status error "failed to setup 7Zip dependency."
	exit 1
}

$process = 7ZIP-Is-Available
if ($process -ne 0) {
	OS-Print-Status error "7Zip command is not available."
	exit 1
}

$process = 7ZIP-Formulate-Path
OS-Print-Status info "7Zip command is now available at: $process"




# (4) clean up destination path
$dest = $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_PKG
OS-Print-Status info "remaking package directory: $dest"
$process = FS-Remake-Directory $dest
if ($process -ne 0) {
	OS-Print-Status error "remake failed."
	exit 1
}




# (5) begin packaging
foreach ($i in Get-ChildItem -Path "$env:PROJECT_PATH_ROOT\$env:PROJECT_PATH_BUILD") {
	if (FS-IsDirectory $i) {
		continue
	}
	OS-Print-Status info "detected $env:PROJECT_PATH_ROOT\$env:PROJECT_PATH_BUILD\$i"


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


	# (5.2) archive into tar.xz / zip package
	$src = "archive_$TARGET_FILENAME_$TARGET_OS-$TARGET_ARCH"
	$src = "$env:PROJECT_PATH_ROOT\$env:PROJECT_PATH_TEMP\$src"
	OS-Print-Status info "processing $src for $TARGET_OS-$TARGET_ARCH"
	$dest = "$env:PROJECT_PATH_ROOT\$env:PROJECT_PATH_PKG"

	# (5.2.1) copy necessary complimentary files to the package
	OS-Print-Status info "remaking workspace directory: $src"
	$process = FS-Remake-Directory $src
	if ($process -ne 0) {
		OS-Print-Status error "remake failed."
		exit 1
	}

	$file = $env:PROJECT_PATH_ROOT + "\" + $env:PROJECT_PATH_BUILD + "\" + $i
	OS-Print-Status info "copying $file into $src"
	$process = FS-Copy-File $file "$src\$TARGET_FILENAME"
	if ($process -ne 0) {
		OS-Print-Status error "copy failed."
		exit 1
	}

	$file = $env:PROJECT_PATH_ROOT + "\USER-GUIDES-EN.pdf"
	OS-Print-Status info "copying $file into $src"
	$process = FS-Copy-File $file "$src\."
	if ($process -ne 0) {
		OS-Print-Status error "copy failed."
		exit 1
	}

	$file = $env:PROJECT_PATH_ROOT + "\LICENSE-EN.pdf"
	OS-Print-Status info "copying $file into $src"
	$process = FS-Copy-File $file "$src\."
	if ($process -ne 0) {
		OS-Print-Status error "copy failed."
		exit 1
	}

	# (5.2.2) begin archiving to .tar.xz/.zip
	switch ($TARGET_OS) {
	"windows" {
		$file="$src\$TARGET_FILENAME"
		OS-Print-Status info "renaming $file to $file.exe"
		$process = FS-Rename "$file" "$file.exe"
		if ($process -ne 0) {
			OS-Print-Status error "rename failed."
			exit 1
		}

		$dest = $dest + "\" `
			+ $TARGET_FILENAME + "_" `
			+ $TARGET_OS + "-" `
			+ $TARGET_ARCH + ".zip"
		OS-Print-Status info "packaging $dest"
		$process = ZIP-Create -Source $src -Destination $dest
		if ($process -ne 0) {
			OS-Print-Status error "packaging failed."
			exit 1
		}
	} default {
		$dest = $dest + "\" `
			+ $TARGET_FILENAME + "_" `
			+ $TARGET_OS + "-" `
			+ $TARGET_ARCH
		OS-Print-Status info "packaging $dest.tar.xz"
		7ZIP-Create-TARXZ -Source $src -Destination $dest
		if ($process -ne 0) {
			OS-Print-Status error "packaging failed."
			exit 1
		}
	}}


	# (5.3) report task verdict
	OS-Print-Status success ""
}
exit 0
