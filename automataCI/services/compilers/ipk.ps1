# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\disk.ps1"
. "${env:LIBS_AUTOMATACI}\services\archive\tar.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\deb.ps1"




function IPK-Create-Archive {
	param (
		[string]$___directory,
		[string]$___destination
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___directory}") -eq 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}/control"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}/data"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory}/control/control"
	if ($___process -ne 0) {
		return 1
	}


	# change directory into workspace
	$___current_path = Get-Location


	# package control
	$null = Set-Location "${___directory}\control"
	$___process = TAR-Create-GZ "${___directory}\control.tar.gz" "."
	if ($___process -ne 0) {
		$null = Set-Location $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# package data
	$null = Set-Location "${___directory}\data"
	$___process = TAR-Create-GZ "${___directory}\data.tar.gz" "."
	if ($___process -ne 0) {
		$null = Set-Location $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# generate debian-binary
	$null = Set-Location "${___directory}"
	$___process = FS-Write-File ".\debian-binary" "2.0`n"
	if ($___process -ne 0) {
		$null = Set-Location $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# archive into ipk
	$___file = "package.ipk"
	$___process = TAR-Create-GZ "${___file}" "debian-binary control.tar.gz data.tar.gz"
	if ($___process -ne 0) {
		$null = Set-Location $___current_path
		$null = Remove-Variable -Name ___current_path
		return 1
	}


	# move to destination
	$null = FS-Remove-Silently "${___destination}"
	$___process = FS-Move "${___file}" "${___destination}"


	# return to current directory
	$null = Set-Location -Path $___current_path
	$null = Remove-Variable -Name ___current_path


	# report status
	if ($___process -ne 0) {
		return 1
	}

	return 0
}




function IPK-Create-Control {
	param (
		[string]$___directory,
		[string]$___resources,
		[string]$___sku,
		[string]$___version,
		[string]$___arch,
		[string]$___os,
		[string]$___name,
		[string]$___email,
		[string]$___website,
		[string]$___pitch,
		[string]$___priority,
		[string]$___section,
		[string]$___description_filepath
	)


	# execute
	$___process = DEB-Create-Control `
		"${___directory}" `
		"${___resources}" `
		"${___sku}" `
		"${___version}" `
		"${___arch}" `
		"${___os}" `
		"${___name}" `
		"${___email}" `
		"${___website}" `
		"${___pitch}" `
		"${___priority}" `
		"${___section}" `
		"${___description_filepath}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function IPK-Get-Architecture {
	param (
		[string]$___os,
		[string]$___arch
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0)) {
		return ""
	}


	# report status
	return STRINGS-To-Lowercase "${___os}-${___arch}"
}




function IPK-Is-Available {
	param(
		[string]$___os,
		[string]$___arch
	)

	if (($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0)) {
		return 1
	}


	# validate dependencies
	$___process = TAR-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___process = DISK-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# check compatible target cpu architecture
	switch ($___arch) {
	{ $_ -in 'any' } {
		return 3
	} Default {
		# accepted
	}}


	# report status
	return 0
}




function IPK-Is-Valid {
	param (
		[string]$___target
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	if ($(${___target} -split '\.')[-1] -eq "ipk") {
		return 0
	}


	# report status
	return 1
}
