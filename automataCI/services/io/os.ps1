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
function OS-Print-Status {
	param (
		[string]$Mode,
		[string]$Message
	)

	$msg = ""
	$start_color = ""
	$stop_color = "`e[0m"

	switch ($Mode)
	{ "error" {
		$msg = "[ ERROR   ] $Message"
		$start_color = "`e[91m"
	} "warning" {
		$msg = "[ WARNING ] $Message"
		$start_color = "`e[93m"
	} "info" {
		$msg = "[ INFO    ] $Message"
		$start_color = "`e[96m"
	} "success" {
		$msg = "[ SUCCESS ] $Message"
		$start_color = "`e[92m"
	} "ok" {
		$msg = "[ INFO    ] == OK =="
		$start_color = "`e[96m"
	} "plain" {
		$msg = $Message -join " "
	} default {
		return
	}}

	if ($Host.UI.RawUI.ForegroundColor -ge "DarkGray") {
		$msg = "$start_color$msg$stop_color"
	}

	Write-Host $msg -Foregroundcolor $Host.UI.RawUI.ForegroundColor
	Remove-Variable -Name msg -ErrorAction SilentlyContinue
	Remove-Variable -Name start_color -ErrorAction SilentlyContinue
	Remove-Variable -Name stop_color -ErrorAction SilentlyContinue
}
