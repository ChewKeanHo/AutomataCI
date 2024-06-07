# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




function FLATPAK-Create-Archive {
	param (
		[string]$___directory,
		[string]$___destination,
		[string]$___repo,
		[string]$___app_id,
		[string]$___gpg_id
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___repo}") -eq 0) -or
		($(STRINGS-Is-Empty "${___app_id}") -eq 0) -or
		($(STRINGS-Is-Empty "${___gpg_id}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___path_build = ".\build"
	$___path_export = ".\export"
	$___path_package = ".\out.flatpak"
	$___path_manifest = ".\manifest.yml"
	$null = FS-Make-Directory "${___repo}"


	# change location into the workspace
	$___current_path = Get-Location
	Set-Location -Path $___directory


	# build archive
	$___process = FS-Is-File "${___path_manifest}"
	if ($___process -ne 0) {
		return 1
	}

	$___arguments = "--user " +
			"--force-clean " +
			"--repo=`"${___repo}`" " +
			"--gpg-sign=`"${___gpg_id}`" " +
			"`"${___path_build}`" " +
			"`"${___path_manifest}`" "
	$___process = OS-Exec "flatpak-builder" "${___arguments}"
	if ($___process -ne 0) {
		Set-Location -Path $___current_path
		Remove-Variable -Name ___current_path
		return 1
	}

	$___process = OS-Exec "flatpak" `
		"build-export `"${___path_export}`" `"${___path_build}`""
	if ($___process -ne 0) {
		Set-Location -Path $___current_path
		Remove-Variable -Name ___current_path
		return 1
	}

	$___arguments = "build-bundle " +
			"`"${___path_export}`" " +
			"`"${___path_package}`" " +
			"`"${___app_id}`" "
	$___process = OS-Exec "flatpak" "${___arguments}"
	if ($___process -ne 0) {
		Set-Location -Path $___current_path
		Remove-Variable -Name ___current_path
		return 1
	}


	# export output
	$___process = FS-Is-File "${___path_package}"
	if ($___process -ne 0) {
		Set-Location -Path $___current_path
		Remove-Variable -Name ___current_path
		return 1
	}

	$___process = FS-Move "${___path_build}" "${___destination}"


	# head back to current directory
	Set-Location -Path "${___current_path}"
	Remove-Variable -Name ___current_path


	# report status
	if ($___process -ne 0) {
		return 1
	}

	return 0
}




function FLATPAK-Is-Available {
	param(
		[string]$___os,
		[string]$___arch
	)

	if (($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0)) {
		return 1
	}


	# check compatible target os
	switch ($___os) {
	{ $_ -in "linux", "any" } {
		# accepted
	} Default {
		return 2
	}}


	# check compatible target cpu architecture
	switch ($___arch) {
	any {
		return 3
	} Default {
		Break
	}}


	# validate dependencies
	$___process = OS-Is-Command-Available "flatpak-builder"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
