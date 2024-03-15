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
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function MICROSOFT-Get-Arch {
	param(
		[string]$___arch
	)


	# execute
	switch ($___arch) {
	i386 {
		return "x86"
	} mips {
		return "MIPs"
	} alpha {
		return "Alpha"
	} powerpc {
		return "PowerPC"
	} arm {
		return "ARM"
	} ia64 {
		return "ia64"
	} amd64 {
		return "x64"
	} arm64 {
		return "ARM64"
	} default {
		return ""
	}}
}




function MICROSOFT-Is-Available-Software {
	param(
		[string]$___software,
		[string]$___version
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___software}") -eq 0) {
		return 1
	}


	# execute
	$null = Import-Module -UseWindowsPowerShell -Name Appx *>$null
	$___process = Get-AppxPackage -Name $___software
	if (-not $___process) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${___software}") -ne 0) {
		$___process = $___process | Where-Object { $_.Version -eq $___version }
		if (-not $___process) {
			return 1
		}
	}


	# report status
	return 0
}




function MICROSOFT-Is-Available-UIXAML {
	param(
		[string]$___version
	)


	# execute
	return MICROSOFT-Is-Available-Software "Microsoft.UI.Xaml*" $___version
}




function MICROSOFT-Is-Available-VCLibs {
	param (
		[string]$___version
	)


	# execute
	return MICROSOFT-Is-Available-Software "Microsoft.VCLibs*" $___version
}




function MICROSOFT-Setup-UIXAML {
	param (
		[string]$___version
	)


	# validate input
	$___process = MICROSOFT-Is-Available-UIXAML "${___version}"
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___url_bundle = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml"
	if ($(STRINGS-Is-Empty "${___version}") -ne 0) {
		$___url_bundle = "${___url_bundle}/${___version}"
	}
	$___file_bundle = "msft-ui-xaml"

	$null = Invoke-RestMethod -Uri $___url_bundle -OutFile "${___file_bundle}.zip"
	if (-not (Test-Path "${___file_bundle}.zip")) {
		return 1
	}
	$null = Expand-Archive "${___file_bundle}.zip"
	$null = Remove-Item "${___file_bundle}.zip" -ErrorAction SilentlyContinue

	$null = Import-Module -UseWindowsPowerShell -Name Appx *>$null

	$___file_bundle = ".\${___file_bundle}\tools\AppX\x64\Release"
	foreach ($___file in (Get-ChildItem -Path "${___file_bundle}")) {
		if (-not $___file.Name.EndsWith(".appx")) {
			continue
		}

		try {
			$null = Add-AppxProvisionedPackage `
				-Online `
				-SkipLicense `
				-PackagePath $__file.FullName
			$___process = 0
		} catch {
			$___process = 1
		}
		break
	}
	$null = Remove-Item "${___file_bundle}" -Force -Recurse -ErrorAction SilentlyContinue


	# report status
	return $___process
}




function MICROSOFT-Setup-VCLibs {
	param (
		[string]$___version
	)


	# validate input
	$___process = MICROSOFT-Is-Available-VCLibs "${___version}"
	if ($___process -eq 0) {
		return 0
	}

	if ($(STRINGS-Is-Empty "${___version}") -ne 0) {
		$___version = "14.00"
	}


	# execute
	$___url_bundle = "https://aka.ms/Microsoft.VCLibs."
	switch (${env:PROJECT_ARCH}) {
	amd64 {
		$___url_bundle += "x64"
	} arm64 {
		$___url_bundle += "arm64"
	} i386 {
		$___url_bundle += "x86"
	} arm {
		$___url_bundle += "arm"
	} default {
		return 1
	}}
	$___url_bundle += ".${___version}.Desktop.appx"
	$___file_bundle = "msft-vclibs.appx"
	$null = Invoke-RestMethod -Uri $___url_bundle -OutFile $___file_bundle
	try {
		$null = Import-Module -UseWindowsPowerShell -Name Appx *>$null
		$null = Add-AppxProvisionedPackage `
			-Online `
			-SkipLicense `
			-PackagePath "${___file_bundle}"
		$___process = 0
	} catch {
		$___process = 1
	}
	$null = Remove-Item "${___file_bundle}" -Force -Recurse -ErrorAction SilentlyContinue
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function MICROSOFT-Setup-WINGET {
	# validate input
	$___process = OS-Is-Command-Available "winget"
	if ($___process -eq 0) {
		return 0
	}

	$___process = MICROSOFT-Is-Available-VCLibs
	if ($___process -ne 0) {
		return 1
	}

	$___process = MICROSOFT-Is-Available-UIXAML
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	$___url = $(Invoke-RestMethod -Uri $___url).assets.browser_download_url
	$___url_bundle = $___url | Where-Object { $_.EndsWith(".msixbundle") }
	$___file_bundle = "winget.msixbundle"
	$___url_license = $___url | Where-Object { $_.EndsWith("_License1.xml") }
	$___file_license = "winget-license.xml"

	$null = Invoke-RestMethod -Uri $___url_bundle -OutFile $___file_bundle
	if (-not (Test-Path "${___file_bundle}")) {
		return 1
	}

	$null = Invoke-RestMethod -Uri $___url_license -OutFile $___file_license
	if (-not (Test-Path "${___file_license}")) {
		return 1
	}

	try {
		$null = Import-Module -UseWindowsPowerShell -Name Appx *>$null
		$null = Add-AppxProvisionedPackage `
			-PackagePath $___file_bundle `
			-LicensePath $___file_license `
			-Online
		$___process = 0
	} catch {
		$___process = 1
	}
	$null = Remove-Item $___file_bundle -ErrorAction SilentlyContinue
	$null = Remove-Item $___file_license -ErrorAction SilentlyContinue
	if ($___process -ne 0) {
		return 1
	}


	# Sleep for letting winget get into the path because the installer is a buggy mess
	Start-Sleep -s 5
	$null = OS-Sync
	$___process = OS-Is-Command-Available "winget"
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}
