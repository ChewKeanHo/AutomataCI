# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"




function PACKAGE-Assemble-FLATPAK-Content {
	param(
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# validate target before job
	switch ($_target_arch) {
	{ $_ -in "avr" } {
		return 10 # not applicable
	} default {
		# accepted
	}}

	if ($(FS-Is-Target-A-Source "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Docs "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Library "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM-JS "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-WASM "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Chocolatey "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Homebrew "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-Cargo "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-MSI "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif ($(FS-Is-Target-A-PDF "${_target}") -eq 0) {
		return 10 # not applicable
	} elseif (($_target_os -ne "linux") -and ($_target_os -ne "any")) {
		return 10 # not applicable
	}


	# copy main program
	$_filepath = "${_directory}\${env:PROJECT_SKU}"
	$null = I18N-Copy "${_target}" "${_filepath}"
	$___process = FS-Copy-File "${_target}" "${_filepath}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}


	# copy icon.svg
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}"
	$_target = "${_target}\icons\icon.svg"
	$_filepath = "${_directory}\icon.svg"
	$null = I18N-Copy "${_target}" "${_filepath}"
	$___process = FS-Copy-File "${_target}" "${_filepath}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}


	# copy icon-48x48.png
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}"
	$_target = "${_target}\icons\icon-48x48.png"
	$_filepath = "${_directory}\icon-48x48.png"
	$null = I18N-Copy "${_target}" "${_filepath}"
	$___process = FS-Copy-File "${_target}" "${_filepath}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}


	# copy icon-128x128.png
	$_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}"
	$_target = "${_target}\icons\icon-128x128.png"
	$_filepath = "${_directory}\icon-128x128.png"
	$null = I18N-Copy "${_target}" "${_filepath}"
	$___process = FS-Copy-File "${_target}" "${_filepath}"
	if ($___process -ne 0) {
		$null = I18N-Copy-Failed
		return 1
	}


	# [ COMPULSORY ] script manifest.yml
	$__file = "${_directory}\manifest.yml"
	$null = I18N-Create "${__file}"
	$___process = FS-Write-File "${__file}" @"
app-id: ${env:PROJECT_APP_ID}
branch: ${_target_arch}
default-branch: any
command: ${env:PROJECT_SKU}
runtime: ${env:PROJECT_FLATPAK_RUNTIME}
runtime-version: '${env:PROJECT_FLATPAK_RUNTIME_VERSION}'
sdk: ${env:PROJECT_FLATPAK_SDK}
finish-args:
  - "--share=network"
  - "--socket=pulseaudio"
  - "--filesystem=home"
modules:
  - name: ${env:PROJECT_SKU}-main
    buildsystem: simple
    no-python-timestamp-fix: true
    build-commands:
      - install -D ${env:PROJECT_SKU} /app/bin/${env:PROJECT_SKU}
    sources:
      - type: file
        path: ${env:PROJECT_SKU}
  - name: ${env:PROJECT_SKU}-appdata
    buildsystem: simple
    build-commands:
      - install -D appdata.xml /app/share/metainfo/${env:PROJECT_APP_ID}.appdata.xml
    sources:
      - type: file
        path: appdata.xml
  - name: ${env:PROJECT_SKU}-icon-svg
    buildsystem: simple
    build-commands:
      - install -D icon.svg /app/share/icons/hicolor/scalable/apps/${env:PROJECT_SKU}.svg
    sources:
      - type: file
        path: icon.svg
  - name: ${env:PROJECT_SKU}-icon-48x48-png
    buildsystem: simple
    build-commands:
      - install -D icon-48x48.png /app/share/icons/hicolor/48x48/apps/${env:PROJECT_SKU}.png
    sources:
      - type: file
        path: icon-48x48.png
  - name: ${env:PROJECT_SKU}-icon-128x128-png
    buildsystem: simple
    build-commands:
      - install -D icon-128x128.png /app/share/icons/hicolor/128x128/apps/${env:PROJECT_SKU}.png
    sources:
      - type: file
        path: icon-128x128.png

"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# [ COMPULSORY ] script appdata.xml
	$__file = "${_directory}\appdata.xml"
	$null = I18N-Create "${__file}"
	$___process = FS-Write-File "${__file}" @"
<?xml version='1.0' encoding='UTF-8'?>
<!-- refer: https://www.freedesktop.org/software/appstream/docs/chap-Metadata.html -->
<component>
	<id>${env:PROJECT_APP_ID}</id>
	<name>${env:PROJECT_NAME}</name>
	<summary>${env:PROJECT_PITCH}</summary>
	<icon type='stock'>web-browser</icon>
	<metadata_license>CC0-1.0</metadata_license>
	<project_license>${env:PROJECT_LICENSE}</project_license>
	<categories>
		<!-- refer: https://specifications.freedesktop.org/menu-spec/latest/apa.html -->
		<category>Network</category>
		<category>Web</category>
	</categories>
	<keywords>
		<keyword>internet</keyword>
		<keyword>web</keyword>
		<keyword>browser</keyword>
	</keywords>
	<url type='homepage'>${env:PROJECT_CONTACT_WEBSITE}</url>
	<url type='contact'>${env:PROJECT_CONTACT_WEBSITE}</url>
	<screenshots>
		<screenshot type='default'>
			<caption>Example Use</caption>
			<image type='source' width='800' height='600'>
				${env:PROJECT_CONTACT_WEBSITE}/screenshot-800x600.png
			</image>
		</screenshot>
	</screenshots>
	<provides>
		<binary>${env:PROJECT_SKU}</binary>
	</provides>
</component>

"@
	if ($___process -ne 0) {
		$null = I18N-Create-Failed
		return 1
	}


	# report status
	return 0
}
