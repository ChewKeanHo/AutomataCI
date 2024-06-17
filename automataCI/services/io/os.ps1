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
		[string]$___arguments,
		[string]$___log_stdout,
		[string]$___log_stderr
	)


	# validate input
	if ([string]::IsNullOrEmpty($___command)) {
		return 1
	}


	# get program fullpath
	if (Test-Path -Path "${___command}" -ErrorAction SilentlyContinue) {
		$___program = "${___command}"
	} else {
		$___program = Get-Command $___command -ErrorAction SilentlyContinue
		if (-not ($___program)) {
			return 1
		}
	}


	# execute command
	if ([string]::IsNullOrEmpty($___arguments)) {
		if ((-not [string]::IsNullOrEmpty($___log_stdout)) -and
			(-not [string]::IsNullOrEmpty($___log_stderr))) {
			$___process = Start-Process -Wait `
						-FilePath "${___program}" `
						-NoNewWindow `
						-PassThru `
						-RedirectStandardOutput "${___log_stdout}" `
						-RedirectStandardError "${___log_stderr}"
		} elseif (-not [string]::IsNullOrEmpty($___log_stdout)) {
			$___process = Start-Process -Wait `
						-FilePath "${___program}" `
						-NoNewWindow `
						-PassThru `
						-RedirectStandardOutput "${___log_stdout}"
		} elseif (-not [string]::IsNullOrEmpty($___log_stderr)) {
			$___process = Start-Process -Wait `
						-FilePath "${___program}" `
						-NoNewWindow `
						-PassThru `
						-RedirectStandardError "${___log_stderr}"
		} else {
			$___process = Start-Process -Wait `
						-FilePath "${___program}" `
						-NoNewWindow `
						-PassThru
		}
	} else {
		if ((-not [string]::IsNullOrEmpty($___log_stdout)) -and
			(-not [string]::IsNullOrEmpty($___log_stderr))) {
			$___process = Start-Process -Wait `
						-FilePath "${___program}" `
						-NoNewWindow `
						-PassThru `
						-ArgumentList "${___arguments}" `
						-RedirectStandardOutput "${___log_stdout}" `
						-RedirectStandardError "${___log_stderr}"
		} elseif (-not [string]::IsNullOrEmpty($___log_stdout)) {
			$___process = Start-Process -Wait `
						-FilePath "${___program}" `
						-NoNewWindow `
						-PassThru `
						-ArgumentList "${___arguments}" `
						-RedirectStandardOutput "${___log_stdout}"
		} elseif (-not [string]::IsNullOrEmpty($___log_stderr)) {
			$___process = Start-Process -Wait `
						-FilePath "${___program}" `
						-NoNewWindow `
						-PassThru `
						-ArgumentList "${___arguments}" `
						-RedirectStandardError "${___log_stderr}"
		} else {
			$___process = Start-Process -Wait `
						-FilePath "${___program}" `
						-NoNewWindow `
						-PassThru `
						-ArgumentList "${___arguments}"
		}
	}
	if ($___process.ExitCode -ne 0) {
		return 1
	}


	# report status
	return 0
}




function OS-Is-Run-Simulated {
	# execute
	if (-not ([string]::IsNullOrEmpty("${env:PROJECT_SIMULATE_RUN}"))) {
		return 0
	}


	# report status
	return 1
}




function OS-Remove-Path {
	param(
		[string]$___path
	)


	# validate input
	if ([string]::IsNullOrEmpty("${___path}")) {
		return 1
	}


	# execute
	$env:Path = ($env:Path.Split(';') | Where-Object { $_ -ne "${___path}" }) -join ';'


	# report status
	return 0
}




function OS-Sync {
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
		+ ";" `
		+ [System.Environment]::GetEnvironmentVariable("Path","User")
}
