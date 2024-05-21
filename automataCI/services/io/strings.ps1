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
function STRINGS-Has-Prefix {
	param(
		[string]$___prefix,
		[string]$___content
	)


	# validate input
	$___process = STRINGS-Is-Empty "${___prefix}"
	if ($___process -eq 0) {
		return 1
	}


	# execute
	if ($___content.StartsWith($___prefix)) {
		return 0
	}


	# report status
	return 1
}




function STRINGS-Has-Suffix {
	param(
		[string]$___suffix,
		[string]$___content
	)


	# validate input
	$___process = STRINGS-Is-Empty "${___suffix}"
	if ($___process -eq 0) {
		return 1
	}


	# execute
	if ($___content.EndsWith($___suffix)) {
		return 0
	}


	# report status
	return 1
}




function STRINGS-Is-Empty {
	param(
		$___target
	)


	# execute
	if ([string]::IsNullOrEmpty($___target)) {
		return 0
	}


	# report status
	return 1
}




function STRINGS-Replace-All {
	param(
		[string]$___content,
		[string]$___subject,
		[string]$___replacement
	)


	# validate input
	$___process = STRINGS-Is-Empty "${___content}"
	if ($___process -eq 0) {
		return ""
	}

	$___process = STRINGS-Is-Empty "${___subject}"
	if ($___process -eq 0) {
		return $___content
	}

	$___process = STRINGS-Is-Empty "${___replacement}"
	if ($___process -eq 0) {
		return $___content
	}


	# execute
	$___right = $___content
	$___register = ""
	while ($___right) {
		$___left = $___right -replace "$($___subject).*", ""

		if ($___left -eq $___right) {
			return "${___register}${___right}"
		}

		# replace this occurence
		$___register += "${___left}${___replacement}"
		$___right = $___right -replace "^.*?${___subject}", ""
	}


	# report status
	return $___register
}




function STRINGS-To-Lowercase {
	param(
		[string]$___content
	)


	# execute
	return $___content.ToLower()
}




function STRINGS-To-Titlecase {
	param(
		[string]$___content
	)


	# validate input
	$___process = STRINGS-Is-Empty "${___content}"
	if ($___process -eq 0) {
		return ""
	}


	# execute
	$___buffer = ""
	$___resevoir = "${___content}"
	$___trigger = $true
	while ($___resevoir -ne "") {
		## extract character
		$___char = $___resevoir.Substring(0, 1)
		if ($___char -eq "``") {
			$___char = $___resevoir.Substring(0, 2)
		}
		$___resevoir = $___resevoir -replace "^${___char}", ""

		## process character
		if ($___trigger ) {
			$___char = $___char.ToUpper()
		} else {
			$___char = $___char.ToLower()
		}
		$___buffer += $___char

		## set next character action
		switch ("${___char}") {
		{ $_ -in " ", "`r", "`n" } {
			$___trigger = $true
		} default {
			$___trigger = $false
		}}
	}


	# report status
	return $___buffer
}




function STRINGS-To-Uppercase {
	param(
		[string]$___content
	)


	# execute
	return $___content.ToUpper()
}




function STRINGS-Trim-Whitespace-Left {
	param(
		[string]$___content
	)


	# execute
	return $___content.TrimStart()
}




function STRINGS-Trim-Whitespace-Right {
	param(
		[string]$___content
	)


	# execute
	return $___content.TrimEnd()
}




function STRINGS-Trim-Whitespace {
	param(
		[string]$___content
	)


	# execute
	$___content = STRINGS-Trim-Whitespace-Left $___content
	$___content = STRINGS-Trim-Whitespace-Right $___content


	# report status
	return $___content
}
