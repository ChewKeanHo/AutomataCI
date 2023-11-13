#!/bin/sh
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
. "${env:LIBS_AUTOMATACI}\services\io\time.ps1"




function RANDOM-Create-BINARY {
	param(
		[long]$___length
	)


	# execute
	return RANDOM-Create-Data "${___length}" "01"
}




function RANDOM-Create-Data {
	param(
		[long]$___length,
		[string]$___charset
	)


	# validate input
	if ($___length -le 0) {
		$___length = 33
	}

	$__process = STRINGS-Is-Empty "${___charset}"
	if ($__process -eq 0) {
		return ""
	}


	# execute
	$___outcome = [char[]]@(0) * $___length
	$___bytes = [byte[]]@(0) * $___length
	$___crypter = [System.Security.Cryptography.RandomNumberGenerator]::Create()
	$null = $___crypter.GetBytes($___bytes)
	$null = $___crypter.Dispose()

	for ($___i = 0; $___i -lt $___length; $___i++) {
		$___index = [int] ($___bytes[$___i] % $___charset.Length)
		$___outcome[$___i] = [char] $___charset[$___index]
	}


	# report status
	return $___outcome -join "";
}




function RANDOM-Create-DECIMAL {
	param(
		[long]$___length
	)


	# execute
	return RANDOM-Create-Data "${___length}" "0123456789"
}




function RANDOM-Create-HEX {
	param(
		[long]$___length
	)


	# execute
	return RANDOM-Create-Data "${___length}" "0123456789ABCDEF"
}




function RANDOM-Create-STRING {
	param(
		[long]$___length,
		[string]$___charset
	)


	# validate input
	$__process = STRINGS-Is-Empty "${___charset}"
	if ($__process -eq 0) {
		$___charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		$___charset += "abcdefghijklmnopqrstuvwxyz"
		$___charset += "0123456789"
	}


	# execute
	return RANDOM-Create-Data "${___length}" "${___charset}"
}




function RANDOM-Create-UUID {
	# execute
	$___length_data = 24
	$___length_epoch = 8

	$___data = "$(RANDOM-Create-HEX $___length_data)"
	$___epoch = '{0:X}' -f ([int] $(Time-Now))

	$___output = ""
	$___length_data -= 1
	$___length_epoch -= 1
	for ($___count = 0; $___count -lt 32; $___count++) {
		switch ($___count) {
		{ $_ -in 8, 12, 16, 20 } {
			# add uuid dashes at correct index
			$___output += "-"
		}  default {
			# do nothing
		}}

		if (($(RANDOM-Create-BINARY 1) -eq "1") -and ($___length_epoch -ge 0)) {
			# gamble and add 1 character from epoch if won
			$___output += $___epoch.Substring(0,1)
			$___epoch = $___epoch.Substring(1)
			$___length_epoch -= 1
		} elseif ($___length_data -ge 0) {
			# add random character otherwise
			$___output += $___data.Substring(0,1)
			$___data = $___data.Substring(1)
			$___length_data -= 1
		} elseif ($___length_epoch -ge 0) {
			# only epoch left
			$___output += $___epoch.Substring(0,1)
			$___epoch = $___epoch.Substring(1)
			$___length_epoch -= 1
		} else {
			# impossible error edge cases - return nothing and fail
			#                               is better than faulty.
			return ""
		}
	}


	# report status
	return $___output
}
