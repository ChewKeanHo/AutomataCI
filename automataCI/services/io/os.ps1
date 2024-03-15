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
function OS-Get-Arch {
	# execute
	switch ((Get-ComputerInfo).CsProcessors.Architecture) {
	"Alpha" {
		return "alpha"
	} "ARM" {
		return "arm"
	} "ARM64" {
		return "arm64"
	} "ia64" {
		return "ia64"
	} "MIPs" {
		return "mips"
	} "PowerPC" {
		return "powerpc"
	} "x86" {
		return "i386"
	} "x64" {
		return "amd64"
	} Default {
		return ""
	}}
}




function OS-Get-CPU {
	$___output = [System.Environment]::ProcessorCount
	if (([string]::IsNullOrEmpty($___output)) -or (${___output} -eq 0)) {
		$___output = 1
	}


	# report status
	return $___output
}




function OS-Get {
	$___output = (Get-ComputerInfo).OsName.ToLower()
	if (-not ($___output -match "microsoft" -or $___output -match "windows")) {
		return ""
	}

	return "windows"
}




function OS-Get-Lang {
	$___lang = Get-WinSystemLocale
	$fullLanguageCode = $___lang.Name
	$___lang = $___lang -replace '[_-][A-Z]*$', ''
	$___lang = $___lang -replace '_', '-'

	return $___lang
}




function OS-Is-Command-Available {
	param (
		[string]$___command
	)


	# validate input
	if ([string]::IsNullOrEmpty($___command)) {
		return 1
	}


	# execute
	$__program = Get-Command $___command -ErrorAction SilentlyContinue
	if ($__program) {
		return 0
	}


	# report status
	return 1
}




function OS-Exec {
	param (
		[string]$___command,
		[string]$___arguments
	)


	# validate input
	if ([string]::IsNullOrEmpty($___command) -or [string]::IsNullOrEmpty($___arguments)) {
		return 1
	}


	# get program
	$___program = Get-Command $___command -ErrorAction SilentlyContinue
	if (-not ($___program)) {
		return 1
	}


	# execute command
	$___process = Start-Process -Wait `
				-FilePath "${___program}" `
				-NoNewWindow `
				-ArgumentList "${___arguments}" `
				-PassThru
	if ($___process.ExitCode -ne 0) {
		return 1
	}


	# report status
	return 0
}




function OS-Is-Run-Simulated {
	# execute
	if (-not ([string]::IsNullOrEmpty("${env:PROJECT_SIMULATE_RELEASE_REPO}"))) {
		return 0
	}


	# report status
	return 1
}




function OS-Sync {
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")
}




function OS-Print-Status {
	# NOTE: to be scrapped soon!
	param (
		[string]$__mode,
		[string]$__message
	)

	$__tag = ""
	$__color = ""
	$__foreground_color = "Gray"

	switch ($__mode) {
	"error" {
		$__tag = [char]::ConvertFromUtf32(0x2997) `
			+ " ERROR " `
			+ [char]::ConvertFromUtf32(0x2998) `
			+ "   "
		$__color = "31"
		$__foreground_color = "Red"
	} "warning" {
		$__tag = [char]::ConvertFromUtf32(0x2997) `
			+ " WARNING " `
			+ [char]::ConvertFromUtf32(0x2998) `
			+ " "
		$__color = "33"
		$__foreground_color = "Yellow"
	} "info" {
		$__tag = [char]::ConvertFromUtf32(0x2997) `
			+ " INFO " `
			+ [char]::ConvertFromUtf32(0x2998) `
			+ "    "
		$__color = "36"
		$__foreground_color = "Cyan"
	} "note" {
		$__tag = [char]::ConvertFromUtf32(0x2997) `
			+ " NOTE " `
			+ [char]::ConvertFromUtf32(0x2998) `
			+ "    "
		$__color = "35"
		$__foreground_color = "Magenta"
	} "success" {
		$__tag = [char]::ConvertFromUtf32(0x2997) `
			+ " SUCCESS " `
			+ [char]::ConvertFromUtf32(0x2998) `
			+ " "
		$__color = "32"
		$__foreground_color = "Green"
	} "ok" {
		$__tag = [char]::ConvertFromUtf32(0x2997) `
			+ " OK " `
			+ [char]::ConvertFromUtf32(0x2998) `
			+ "      "
		$__color = "36"
		$__foreground_color = "Cyan"
	} "done" {
		$__tag = [char]::ConvertFromUtf32(0x2997) `
			+ " DONE " `
			+ [char]::ConvertFromUtf32(0x2998) `
			+ "    "
		$__color = "36"
		$__foreground_color = "Cyan"
	} "plain" {
		# do nothing
	} default {
		return
	}}

	if (($Host.UI.RawUI.ForegroundColor -ge "DarkGray") -or
		("$env:TERM" -eq "xterm-256color") -or
		("$env:COLORTERM" -eq "truecolor", "24bit")) {
		Write-Host `
			-ForegroundColor $__foreground_color `
			"$([char]0x1b)[1;${__color}m${__tag}$([char]0x1b)[0;${__color}m${__message}$([char]0x1b)[0m"
	} else {
		Write-Host "${__tag}${__message}"
	}

	Remove-Variable -Name __mode -ErrorAction SilentlyContinue
	Remove-Variable -Name __tag -ErrorAction SilentlyContinue
	Remove-Variable -Name __message -ErrorAction SilentlyContinue
	Remove-Variable -Name __color -ErrorAction SilentlyContinue
}
