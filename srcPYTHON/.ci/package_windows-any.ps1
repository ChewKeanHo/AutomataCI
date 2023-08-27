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

$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\io\os.ps1"
. $services

$services = $env:PROJECT_PATH_ROOT + "\" `
		+ $env:PROJECT_PATH_AUTOMATA + "\" `
		+ "services\io\fs.ps1"
. $services




function PACKAGE-Assemble-Archive-Content {
	param(
		[string]$Target,
		[string]$Directory,
		[string]$TargetName,
		[string]$TargetOS,
		[string]$TargetArch
	)

	# copy main program
	OS-Print-Status info "copying $Target to $Directory"
	switch ($TargetOS) {
	"windows" {
		$process = Fs-Copy-File $Target "$Directory\$env:PROJECT_SKU.exe"
	} Default {
		$process = Fs-Copy-File $Target "$Directory\$env:PROJECT_SKU"
	}}
	if ($process -ne 0) {
		$null = Remove-Variable -name Target
		$null = Remove-Variable -name Directory
		$null = Remove-Variable -name TargetName
		$null = Remove-Variable -name TargetOS
		$null = Remove-Variable -name TargetArch
		return 1
	}

	# copy user guide
	$Target = $env:PROJECT_PATH_ROOT + "\" + "USER-GUIDES-EN.pdf"
	OS-Print-Status info "copying $Target to $Directory"
	FS-Copy-File $Target $Directory
	if ($process -ne 0) {
		$null = Remove-Variable -name Target
		$null = Remove-Variable -name Directory
		$null = Remove-Variable -name TargetName
		$null = Remove-Variable -name TargetOS
		$null = Remove-Variable -name TargetArch
		return 1
	}

	# copy license file
	$Target = $env:PROJECT_PATH_ROOT + "\" + "LICENSE-EN.pdf"
	OS-Print-Status info "copying $Target to $Directory"
	FS-Copy-File $Target $Directory
	if ($process -ne 0) {
		$null = Remove-Variable -name Target
		$null = Remove-Variable -name Directory
		$null = Remove-Variable -name TargetName
		$null = Remove-Variable -name TargetOS
		$null = Remove-Variable -name TargetArch
		return 1
	}

	# report status
	$null = Remove-Variable -name Target
	$null = Remove-Variable -name Directory
	$null = Remove-Variable -name TargetName
	$null = Remove-Variable -name TargetOS
	$null = Remove-Variable -name TargetArch
	return 0
}

function PACKAGE-Assemble-DEB-Content {
	param(
		[string]$Target,
		[string]$Directory,
		[string]$TargetName,
		[string]$TargetOS,
		[string]$TargetArch
	)

	# copy main program
	# TIP: (1) usually is: usr/local/bin or usr/local/sbin
	#      (2) please avoid: bin/, usr/bin/, sbin/, and usr/sbin/
	$Filepath = $Directory + "\data\user\local\bin\" + $env:PROJECT_SKU
	OS-Print-Status info "copying $Target to $Filepath"

	FS-Make-Directory (Split-Path -Parent $Filepath)
	if ($process -ne 0) {
		$null = Remove-Variable -name Filepath
		$null = Remove-Variable -name Target
		$null = Remove-Variable -name Directory
		$null = Remove-Variable -name TargetName
		$null = Remove-Variable -name TargetOS
		$null = Remove-Variable -name TargetArch
		return 1
	}

	FS-Copy-File $Target $Filepath
	if ($process -ne 0) {
		$null = Remove-Variable -name Filepath
		$null = Remove-Variable -name Target
		$null = Remove-Variable -name Directory
		$null = Remove-Variable -name TargetName
		$null = Remove-Variable -name TargetOS
		$null = Remove-Variable -name TargetArch
		return 1
	}

	# OPTIONAL (overrides): copy usr/share/docs/$env:PROJECT_SKU/changelog.gz
	# OPTIONAL (overrides): copy usr/share/docs/$env:PROJECT_SKU/copyright.gz
	# OPTIONAL (overrides): copy usr/share/man/man1/$env:PROJECT_SKU.1.gz
	# OPTIONAL (overrides): generate $Directory/control/md5sum
	# OPTIONAL (overrides): generate $Directory/control/control

	# report status
	$null = Remove-Variable -name Filepath
	$null = Remove-Variable -name Target
	$null = Remove-Variable -name Directory
	$null = Remove-Variable -name TargetName
	$null = Remove-Variable -name TargetOS
	$null = Remove-Variable -name TargetArch
	return 0
}
