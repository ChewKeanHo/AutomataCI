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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"




function FLATPAK-Is-Available {
	param(
		[string]$__os,
		[string]$__arch
	)

	if ([string]::IsNullOrEmpty($__os) -or [string]::IsNullOrEmpty($__arch)) {
		return 1
	}

	# check compatible target os
	switch ($__os) {
	windows {
		return 2
	} darwin {
		return 2
	} Default {
		Break
	}}

	# check compatible target cpu architecture
	switch ($__arch) {
	any {
		return 3
	} Default {
		Break
	}}

	# validate dependencies
	$__process = OS-Is-Command-Available "flatpak-builder"
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function FLATPAK-Create-AppInfo {
	param (
		[string]$__directory,
		[string]$__resources
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or [string]::IsNullOrEmpty($__resources)) {
		return 1
	}

	# check for overriding manifest file
	if (Test-Path "${__directory}\appdata.xml") {
		return 2
	}

	# check appinfo is available
	if (-not (Test-Path "${__resources}\packages\flatpak.xml")) {
		return 1
	}

	# copy flatpak.xml to workspace
	return FS-Copy-File "${__resources}\packages\flatpak.xml" "${__directory}\appdata.xml"
}




function FLATPAK-Create-Manifest {
	param (
		[string]$__location,
		[string]$__resources,
		[string]$__app_id,
		[string]$__sku,
		[string]$__arch,
		[string]$__runtime,
		[string]$__runtime_version,
		[string]$__sdk
	)

	# validate input
	if ([string]::IsNullOrEmpty($__location) -or
		[string]::IsNullOrEmpty($__resources) -or
		[string]::IsNullOrEmpty($__app_id) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__arch) -or
		[string]::IsNullOrEmpty($__runtime) -or
		[string]::IsNullOrEmpty($__runtime_version) -or
		[string]::IsNullOrEmpty($__sdk) -or
		(-not (Test-Path $__resources -PathType Container)) -or
		(-not (Test-Path $__location -PathType Container))) {
		return 1
	}

	# check for overriding manifest file
	if ((Test-Path "${__location}\manifest.yml") -or
		(Test-Path "${__location}\manifest.json")) {
		return 2
	}

	# generate manifest app metadata fields
	$__target = "${__location}\manifest.yml"
	$null = FS-Write-File "${__target}" @"
app-id: ${__app_id}
branch: ${__arch}
default-branch: any
command: ${__sku}
runtime: ${__runtime}
runtime-version: '${__runtime_version}'
sdk: ${__sdk}
modules:
  - name: ${__sku}-binary
    buildsystem: simple
    build-commands:
      - install -D ${__sku} /app/bin/${__sku}
    sources:
      - type: file
        path: ${__sku}
  - name: ${__sku}-appinfo
    buildsystem: simple
    build-commands:
      - install -D appdata.xml /app/share/metainfo/${__app_id}.appdata.xml
    sources:
      - type: file
        path: appdata.xml
"@

	# process icon.svg
	if (Test-Path "${__location}\icon.svg") {
		$null = FS-Append-File "${__target}" @"
  - name: ${__sku}-icon-svg
    buildsystem: simple
    build-commands:
      - install -D icon.svg /app/share/icons/hicolor/scalable/apps/${__sku}.svg
    sources:
      - type: file
        path: icon.svg
"@
	}

	# process icon-48x48.png
	if (Test-Path "${__location}\icon-48x48.png") {
		$null = FS-Append-File "${__target}" @"
  - name: ${__sku}-icon-48x48-png
    buildsystem: simple
    build-commands:
      - install -D icon-48x48.png /app/share/icons/hicolor/48x48/apps/${__sku}.png
    sources:
      - type: file
        path: icon-48x48.png
"@
	}

	# process icon-128x128.png
	if (Test-Path "${__location}\icon-128x128.png") {
		$null = FS-Append-File "${__target}" @"
  - name: ${__sku}-icon-128x128-png
    buildsystem: simple
    build-commands:
      - install -D icon-128x128.png /app/share/icons/hicolor/128x128/apps/${__sku}.png
    sources:
      - type: file
        path: icon-128x128.png
"@
	}

	# append more setup if available
	if (Test-Path "${__resources}\packages\flatpak.yml") {
		foreach($__line in Get-Content "${__resources}\packages\flatpak.yml") {
			$__line = $_ -replace '#.*'
			$__key = $__line -replace ':.*'
			$__key = STRINGS-Trim-Whitespace $__key

			if ([string]::IsNullOrEmpty($__line) -or ($__key == "modules")) {
				continue
			}

			$null = FS-Append-File $__target "${__line}`n"
		}
	}

	# report status
	return 0
}




function FLATPAK-Create-Archive {
	param (
		[string]$__directory,
		[string]$__destination,
		[string]$__app_id,
		[string]$__gpg_id
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__destination) -or
		[string]::IsNullOrEmpty($__app_id) -or
		[string]::IsNullOrEmpty($__gpg_id) -or
		(-not (Test-Path $__directory -PathType Container))) {
		return 1
	}

	$__path_build = ".\build"
	$__path_manifest = ".\manifest.yml"
	if (-not (Test-Path $__path_manifest)) {
		return 1
	}

	# change location into the workspace
	$__current_path = Get-Location
	Set-Location -Path $__directory

	# build archive
	$__arguments = "--force-clean " +
			"--gpg-sign=`"${__gpg_id}`" " +
			"`"${__path_build}`" " +
			"`"${__path_manifest}`""
	$__process = OS-Exec "flatpak-builder" $__arguments
	if ($__process -ne 0) {
		Set-Location -Path $__current_path
		Remove-Variable -Name __current_path
		return 1
	}

	# export output
	$__process = FS-Move "${__path_build}" "${__destination}"

	# head back to current directory
	Set-Location -Path ${__current_path}
	Remove-Variable -Name __current_path

	# report status
	return $__process
}
