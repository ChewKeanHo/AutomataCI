# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\dotnet.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\microsoft.ps1"




function MSI-Compile {
	param (
		[string]$___target,
		[string]$___arch,
		[string]$___lang
	)


	# validate input
	$___process = MSI-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${___target}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___arch = MICROSOFT-Get-Arch "${___arch}"
	if ($(STRINGS-Is-Empty "${___arch}") -eq 0) {
		return 1
	}

	$___lang = MSI-Get-Culture "${___lang}"
	if ($(STRINGS-Is-Empty "${___lang}") -eq 0) {
		return 1
	}


	# execute
	$___arguments = @"
build -arch ${___arch} -culture ${___lang} -out `"$(FS-Extension-Replace "${___target}" ".wxs" ".msi")`"
"@

	foreach ($___ext in (Get-ChildItem "$(FS-Get-Directory "${___target}")\ext" -File -Filter "*.dll")) {
		$___arguments += " -ext ${___ext}"
	}
	$___arguments += " ${___target}"

	$___process = OS-Exec "wix" "${___arguments}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function MSI-Get-Directory-Program-Files {
	param(
		[string]$___arch
	)


	# execute
	switch ("${___arch}") {
	{ $_ -in "amd64", "arm64" } {
		return "ProgramFiles64Folder"
	} { $_ -in "i386", "arm" } {
		return "ProgramFilesFolder"
	} default {
		return "ProgramFiles6432Folder"
	}}
}




function MSI-Get-Culture {
	param(
		[string]$___lang
	)


	# execute
	# IMPORTANT NOTE: this is a temporary function for handling WiX's
	#                 localization bug. More info:
	#                 (1) https://github.com/wixtoolset/issues/issues/7896
	#                 (2) https://wixtoolset.org/docs/tools/wixext/wixui/#translated-strings
	switch (STRINGS-To-Lowercase "${___lang}") {
	"ar" {
		return "ar-SA"
	} "bg" {
		return "bg-BG"
	} "ca" {
		return "ca-ES"
	} "cs" {
		return "cs-CZ"
	} "da" {
		return "da-DK"
	} "de" {
		return "de-DE"
	} "el" {
		return "el-GR"
	} "en" {
		return "en-US"
	} "es" {
		return "es-ES"
	} "et" {
		return "et-EE"
	} "fi" {
		return "fi-FI"
	} "fr" {
		return "fr-FR"
	} "he" {
		return "he-IL"
	} "hi" {
		return "hi-IN"
	} "hr" {
		return "hr-HR"
	} "hu" {
		return "hu-HU"
	} "it" {
		return "it-IT"
	} "ja" {
		return "ja-JP"
	} "kk" {
		return "kk-KZ"
	} "ko" {
		return "ko-KR"
	} "lt" {
		return "lt-LT"
	} "lv" {
		return "lv-LV"
	} "nb" {
		return "nb-NO"
	} "nl" {
		return "nl-NL"
	} "pl" {
		return "pl-PL"
	} "pt" {
		return "pt-PT"
	} "ro" {
		return "ro-RO"
	} "ru" {
		return "ru-RU"
	} "sk" {
		return "sk-SK"
	} "sl" {
		return "sl-SI"
	} "sq" {
		return "sq-AL"
	} "sr" {
		return "sr-Latn-RS"
	} "sv" {
		return "sv-SE"
	} "th" {
		return "th-TH"
	} "tr" {
		return "tr-TR"
	} "uk" {
		return "uk-UA"
	} "zh-hant" {
		return "zh-TW"
	} { $_ -in "zh", "zh-hans" } {
		return "zh-CN"
	} default {
		return ""
	}}
}




function MSI-Install-Silent() {
	param(
		[string]$___installer
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___installer}") -eq 0) {
		return 1
	}

	if ($(FS-Is-File "${___installer}") -ne 0) {
		return 1
	}

	if ($(FS-Is-Target-A-MSI "${___installer}") -ne 0) {
		return 1
	}


	# execute
	try {
		$null = Start-Process -FilePath "${___installer}" `
				-ArgumentList "/qn /norestart" `
				-Wait
	} catch {
		return 1
	}


	# report status
	return 0
}




function MSI-Is-Available {
	# execute
	$___process = DOTNET-Activate-Environment
	if ($___process -ne 0) {
		return 1
	}


	$___process = OS-Is-Command-Available "wix"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function MSI-Setup {
	# validate input
	$___process = MSI-Is-Available
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___process = DOTNET-Install "wix"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
