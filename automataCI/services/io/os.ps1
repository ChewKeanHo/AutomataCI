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
function OS-Is-Command-Available {
	param (
		[string] $__command
	)

	# validate input
	if ([string]::IsNullOrEmpty($__command)) {
		return 1
	}

	# execute
	$__program = Get-Command $__command -ErrorAction SilentlyContinue
	if ($__program) {
		return 0
	}
	return 1
}




function OS-Exec {
	param (
		[string]$__command,
		[string]$__arguments
	)

	# validate input
	if ([string]::IsNullOrEmpty($__command) -or [string]::IsNullOrEmpty($__arguments)) {
		return 1
	}

	# get program
	$__program = Get-Command $__command -ErrorAction SilentlyContinue
	if (-not ($__program)) {
		return 1
	}

	# execute command
	$__process = Start-Process -Wait `
				-FilePath "$__program" `
				-NoNewWindow `
				-ArgumentList "$__arguments" `
				-PassThru
	if ($__process.ExitCode -ne 0) {
		return 1
	}
	return 0
}




function OS-Print-Status {
	param (
		[string]$__mode,
		[string]$__message
	)

	$__msg = ""
	$__start_color = ""
	$__stop_color = "`e[0m"

	switch ($__mode) {
	"error" {
		$__msg = "[ ERROR   ] $__message"
		$__start_color = "`e[91m"
	} "warning" {
		$__msg = "[ WARNING ] $__message"
		$__start_color = "`e[93m"
	} "info" {
		$__msg = "[ INFO    ] $__message"
		$__start_color = "`e[96m"
	} "success" {
		$__msg = "[ SUCCESS ] $__message"
		$__start_color = "`e[92m"
	} "ok" {
		$__msg = "[ INFO    ] == OK =="
		$__start_color = "`e[96m"
	} "plain" {
		$__msg = $__message
	} default {
		return
	}}

	if ($Host.UI.RawUI.ForegroundColor -ge "DarkGray") {
		$__msg = "${__start_color}${__msg}${__stop_color}"
	}

	Write-Host $__msg -Foregroundcolor $Host.UI.RawUI.ForegroundColor
	Remove-Variable -Name __mode -ErrorAction SilentlyContinue
	Remove-Variable -Name __msg -ErrorAction SilentlyContinue
	Remove-Variable -Name __message -ErrorAction SilentlyContinue
	Remove-Variable -Name __start_color -ErrorAction SilentlyContinue
	Remove-Variable -Name __stop_color -ErrorAction SilentlyContinue
}
