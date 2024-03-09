# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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

	if ($(STRINGS-Is-Empty "${___lang}") -eq 0) {
		return 1
	}


	# execute
	$___arguments = "build " `
		+ "-arch ${___arch} " `
		+ "-culture ${___lang} " `
		+ "-out `"" + $(FS-Extension-Replace "${___target}" ".wxs" ".msi") + "`" "

	$___extensions = $(Split-Path -Parent -Path "${___target}") + "\ext"
	$___process = FS-Is-Directory "${___extensions}"
	if ($___process -eq 0) {
		foreach ($___ext in (Get-ChildItem "${___extensions}" -Filter "*.dll")) {
			$___arguments += "-ext ${___ext} "
		}
	}
	$___arguments += "`"${___target}`" "

	$___process = OS-Exec "wix" "${___arguments}"
	if ($___process -ne 0) {
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
