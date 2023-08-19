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
IF (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
        Write-Error "[ ERROR ] - Please source from ci.cmd instead!\n"
        exit 1
}




# (1) safety checking control surfaces
$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\zip.ps1"
. $services

$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\7zip.ps1"
. $services

$process = Setup-7Zip
if ($process -ne 0) {
	return 1
}




# (2) clean up destination path
$dest = $env:PROJECT_PATH_ROOT + "/" + $env:PROJECT_PATH_PKG
Remove-Item $dest -ErrorAction SilentlyContinue -Force -Recurse
New-Item -ItemType Directory -Force -Path $dest


# (3) begin packaging
foreach ($i in Get-ChildItem -Path "$($env:PROJECT_PATH_ROOT)\$($env:PROJECT_PATH_BUILD)") {
	if (Test-Path -Path $i -PathType Container) {
		continue
	}

	# (3.1) parse build candidate
	$TARGET_FILENAME = Split-Path -Leaf $i
	$TARGET_FILENAME = $TARGET_FILENAME -replace `
				".*${PROJECT_PATH_ROOT}\${PROJECT_PATH_BUILD}\"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "\..*$"
	$TARGET_OS = $TARGET_FILENAME -replace ".*_"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "_.*"
	$TARGET_ARCH = $TARGET_OS -replace ".*-"
	$TARGET_OS = $TARGET_OS -replace "-.*"

	if (-not $TARGET_OS -or -not $TARGET_ARCH -or -not $TARGET_FILENAME) {
		Write-Host "[ WARNING ] detected $i but failed to parse. Skipping."
		continue
	}

	# (3.2) archive into tar.xz / zip package
	$src = "archive_$TARGET_FILENAME_$TARGET_OS-$TARGET_ARCH"
	Write-Host "[ INFO ] Processing $TARGET_FILENAME for $src"
	$src = "$env:PROJECT_PATH_ROOT\$env:PROJECT_PATH_TEMP\$src"
	$dest = "$env:PROJECT_PATH_ROOT\$env:PROJECT_PATH_PKG"

	# (3.2.1) copy necessary complimentary files to the package
	Remove-Item $src -ErrorAction SilentlyContinue -Force -Recurse
	New-Item -Path $src -ItemType Directory -Force
	Copy-Item -Path ($env:PROJECT_PATH_ROOT + "\" `
			+ $env:PROJECT_PATH_BUILD + "\" `
			+ $i) `
		-Destination "$src\."
	Copy-Item -Path "$env:PROJECT_PATH_ROOT\USER-GUIDES-EN.pdf" -Destination "$src\."
	Copy-Item -Path "$env:PROJECT_PATH_ROOT\LICENSE-EN.pdf" -Destination "$src\."

	# (3.2.2) begin archiving
	switch ($env:TARGET_OS) {
	"windows" {
		Move-Item `
			-Path "$src\$TARGET_FILENAME" `
			-Destination "$src\$TARGET_FILENAME.exe"
		Create-Zip `
			-Path $src `
			-OutputPath "$dest\$TARGET_FILENAME`_windows-$env:TARGET_ARCH.zip"
	} default {
		Create-TARXZ `
			-Source $src `
			-Destination $dest + "\" `
					+ $TARGET_FILENAME + "_" `
					+ $TARGET_OS + "-" + $TARGET_ARCH
	}}
}
exit 0
