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
function I18N-Status-Print {
	param(
		[string]$___mode,
		[string]$___message
	)


	# execute
	$___tag = I18N-Status-Tag-Get-Type "${___mode}"
	$___color = ""
	$___foreground_color = "Gray"
	switch ($___mode) {
	error {
		$___color = "31"
		$___foreground_color = "Red"
	} warning {
		$___color = "33"
		$___foreground_color = "Yellow"
	} info {
		$___color = "36"
		$___foreground_color = "Cyan"
	} note {
		$___color = "35"
		$___foreground_color = "Magenta"
	} success {
		$___color = "32"
		$___foreground_color = "Green"
	} ok {
		$___color = "36"
		$___foreground_color = "Cyan"
	} done {
		$___color = "36"
		$___foreground_color = "Cyan"
	} default {
		# do nothing
	}}

	if (($Host.UI.RawUI.ForegroundColor -ge "DarkGray") -or
		("$env:TERM" -eq "xterm-256color") -or
		("$env:COLORTERM" -eq "truecolor", "24bit")) {
		# terminal supports color mode
		if ((-not ([string]::IsNullOrEmpty($___color))) -and
			(-not ([string]::IsNullOrEmpty($___foreground_color)))) {
			$null = Write-Host `
				-NoNewLine `
				-ForegroundColor $___foreground_color `
				"$([char]0x1b)[1;${___color}m${___tag}$([char]0x1b)[0;${___color}m${___message}$([char]0x1b)[0m"
		} else {
			$null = Write-Host -NoNewLine "${___tag}${___message}"
		}
	} else {
		$null = Write-Host -NoNewLine "${___tag}${___message}"
	}

	$null = Remove-Variable -Name ___mode -ErrorAction SilentlyContinue
	$null = Remove-Variable -Name ___tag -ErrorAction SilentlyContinue
	$null = Remove-Variable -Name ___message -ErrorAction SilentlyContinue
	$null = Remove-Variable -Name ___color -ErrorAction SilentlyContinue
	$null = Remove-Variable -Name ___foreground_color -ErrorAction SilentlyContinue


	# report status
	return 0
}




function I18N-Status-Tag-Create {
	param(
		[string]$___content,
		[string]$___spacing
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___content}") -eq 0) {
		return ""
	}


	# execute
	return "⦗${___content}⦘${___spacing}"
}




function I18N-Status-Tag-Get-Type {
	param(
		[string]$___mode
	)


	# execute
	switch (${env:AUTOMATACI_LANG}) {
	default {
		return I18N-Status-Tag-Get-Type-EN "${___mode}"
	}}
}




function I18N-Status-Tag-Get-Type-EN {
	param(
		[string]$___mode
	)


	# execute (REMEMBER: make sure the text and spacing are having the same length)
	switch ($___mode) {
	error {
		return I18N-Status-Tag-Create " ERROR " "   "
	} warning {
		return I18N-Status-Tag-Create " WARNING " " "
	} info {
		return I18N-Status-Tag-Create " INFO " "    "
	} note {
		return I18N-Status-Tag-Create " NOTE " "    "
	} success {
		return I18N-Status-Tag-Create " SUCCESS " " "
	} ok {
		return I18N-Status-Tag-Create " OK " "      "
	} done {
		return I18N-Status-Tag-Create " DONE " "    "
	} default {
		return ""
	}}
}
