# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function APPIMAGE-Is-Available {
	return 0 # Unsupported - requires linux kernel libfuse2
}




function APPIMAGE-Setup {
	return 0 # Unsupported - requires linux kernel libfuse2
}




function APPIMAGE-Unpack {
	param(
		[string]$___dest,
		[string]$___dir_install,
		[string]$___image
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___dest}") -eq 0) -or
		($(STRINGS-Is-Empty "${___dir_install}") -eq 0) -or
		($(STRINGS-Is-Empty "${___image}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_PATH_TEMP}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:PROJECT_PATH_ROOT}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___dest}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___dir_install}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___image}"
	if ($___process -ne 0) {
		return 1
	}


	# setup a temporary directory
	$___mnt = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\mnt-appimage-$(FS-Get-File "${___dest}")"
	$null = FS-Remake-Directory "${___mnt}"

	try {
		$___diskImage = Mount-DiskImage -ImagePath $___image -PassThru
		$___diskVolume = Get-Volume -DiskImage $___diskImage -ErrorAction Stop
		Add-PartitionAccessPath -DiskNumber $___diskVolume.DiskNumber `
			-PartitionNumber $___diskVolume.PartitionNumber `
			-AccessPath "${___mnt}" `
			-ErrorAction Stop
	} catch {
		return 1
	}

	$___process = FS-Copy-All "${___mnt}\" "${___dir_install}"
	if ($___process -ne 0) {
		return 1
	}

	try {
		$___partition = Get-Partition `
			| Where-Object { $_.AccessPaths -contains $___mnt }
		if ($___partition -eq $null) {
			return 1
		}

		Remove-PartitionAccessPath -DiskNumber $___partition.DiskNumber `
				-PartitionNumber $___partition.PartitionNumber `
				-AccessPath $___mnt -ErrorAction Stop
	} catch {
		return 1
	}

	$null = FS-Remove-Silently "${___mnt}"


	# symlink to dest
	try {
		New-Item -ItemType SymbolicLink `
			-Path $___dest `
			-Target "${___dir_install}\AppRun"
	} catch {
		return 1
	}


	# report status
	return 0
}
