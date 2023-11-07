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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"




function MICROSOFT-Is-Available-Software {
	param(
		[string]$__software,
		[string]$__version
	)


	# validate input
	if ([string]::IsNullOrEmpty($__software)) {
		return 1
	}


	# execute
	$__process = Get-AppxPackage -Name $__software
	if (-not $__process) {
		return 1
	}

	if (-not [string]::IsNullOrEmpty($__version)) {
		$__process = $__process | Where-Object { $_.Version -eq $__version }
		if (-not $__process) {
			return 1
		}
	}


	# report status
	return 0
}




function MICROSOFT-Is-Available-UIXAML {
	param(
		[string]$__version
	)


	# execute
	return MICROSOFT-Is-Available-Software "Microsoft.UI.Xaml*" $__version
}




function MICROSOFT-Is-Available-VCLibs {
	param (
		[string]$__version
	)


	# execute
	return MICROSOFT-Is-Available-Software "Microsoft.VCLibs*" $__version
}




function MICROSOFT-Setup-UIXAML {
	param (
		[string]$__version
	)


	# validate input
	$__process = MICROSOFT-Is-Available-UIXAML "${__version}"
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__url_bundle = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml"
	if (-not [string]::IsNullOrEmpty($__version)) {
		$__url_bundle = "${__url_bundle}/${__version}"
	}
	$__file_bundle = "msft-ui-xaml"

	$null = Invoke-RestMethod -Uri $__url_bundle -OutFile "${__file_bundle}.zip"
	if (-not (Test-Path "${__file_bundle}.zip")) {
		return 1
	}
	$null = Expand-Archive "${__file_bundle}.zip"
	$null = Remove-Item "${__file_bundle}.zip" -ErrorAction SilentlyContinue

	$__file_bundle = ".\${__file_bundle}\tools\AppX\x64\Release"
	foreach ($__file in (Get-ChildItem -Path "${__file_bundle}")) {
		if (-not $__file.Name.EndsWith(".appx")) {
			continue
		}

		try {
			$null = Add-AppxProvisionedPackage `
				-Online `
				-SkipLicense `
				-PackagePath "${__file_bundle}\${__file}"
			$__process = 0
		} catch {
			$__process = 1
		}
		break
	}
	$null = Remove-Item "${__file_bundle}" -Force -Recurse -ErrorAction SilentlyContinue


	# report status
	return $__process
}




function MICROSOFT-Setup-VCLibs {
	param (
		[string]$__version
	)


	# validate input
	$__process = MICROSOFT-Is-Available-VCLibs "${__version}"
	if ($__process -eq 0) {
		return 0
	}

	if ([string]::IsNullOrEmpty($__version)) {
		$__version = "14.00"
	}


	# execute
	switch (${env:PROJECT_ARCH}) {
	amd64 {
		$__url_bundle = "https://aka.ms/Microsoft.VCLibs.x64.${__version}.Desktop.appx"
	} arm64 {
		$__url_bundle = "https://aka.ms/Microsoft.VCLibs.arm64.${__version}.Desktop.appx"
	} i386 {
		$__url_bundle = "https://aka.ms/Microsoft.VCLibs.x86.${__version}.Desktop.appx"
	} arm {
		$__url_bundle = "https://aka.ms/Microsoft.VCLibs.arm.${__version}.Desktop.appx"
	} default {
		return 1
	}}
	$__file_bundle = "msft-vclibs.appx"
	$null = Invoke-RestMethod -Uri $__url_bundle -OutFile $__file_bundle
	try {
		$null = Add-AppxProvisionedPackage `
			-Online `
			-SkipLicense `
			-PackagePath "${__file_bundle}"
		$__process = 0
	} catch {
		$__process = 1
	}
	$null = Remove-Item "${__file_bundle}" -Force -Recurse -ErrorAction SilentlyContinue
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function MICROSOFT-Setup-WinGet {
	# validate input
	$__process = OS-Is-Command-Available "winget"
	if ($__process -eq 0) {
		return 0
	}

	$__process = MICROSOFT-Is-Available-VCLibs
	if ($__process -ne 0) {
		return 1
	}

	$__process = MICROSOFT-Is-Available-UIXAML
	if ($__process -ne 0) {
		return 1
	}


	# execute
	$__url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	$__url = $(Invoke-RestMethod -Uri $__url).assets.browser_download_url
	$__url_bundle = $__url | Where-Object { $_.EndsWith(".msixbundle") }
	$__file_bundle = "winget.msixbundle"
	$__url_license = $__url | Where-Object { $_.EndsWith("_License1.xml") }
	$__file_license = "winget-license.xml"

	$null = Invoke-RestMethod -Uri $__url_bundle -OutFile $__file_bundle
	if (-not (Test-Path "${__file_bundle}")) {
		return 1
	}

	$null = Invoke-RestMethod -Uri $__url_license -OutFile $__file_license
	if (-not (Test-Path "${__file_license}")) {
		return 1
	}

	try {
		$null = Add-AppxProvisionedPackage `
			-PackagePath $__file_bundle `
			-LicensePath $__file_license `
			-Online
		$__process = 0
	} catch {
		$__process = 1
	}
	$null = Remove-Item $__file_bundle -ErrorAction SilentlyContinue
	$null = Remove-Item $__file_license -ErrorAction SilentlyContinue
	if ($__process -ne 0) {
		return 1
	}

	# Sleep for letting winget get into the path because the installer is a buggy mess
	Start-Sleep -s 5

	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")
	$__process = OS-Is-Command-Available "winget"
	if ($__process -eq 0) {
		return 0
	}


	# report status
	return 1
}
