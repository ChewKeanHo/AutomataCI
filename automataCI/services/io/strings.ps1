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
function STRINGS-Trim-Whitespace-Left {
	param(
		[string]$__content
	)

	return $__content.TrimStart()
}




function STRINGS-Trim-Whitespace-Right {
	param(
		[string]$__content
	)

	return $__content.TrimEnd()
}




function STRINGS-Trim-Whitespace {
	param(
		[string]$__content
	)

	$__content = STRINGS-Trim-Whitespace-Left $__content
	$__content = STRINGS-Trim-Whitespace-Right $__content

	return $__content
}




function STRINGS-Has-Prefix {
	param(
		[string]$__prefix,
		[string]$__content
	)

	# validate input
	if ([string]::IsNullOrEmpty($__prefix)) {
		return 1
	}

	# execute
	if ($__content.StartsWith($__prefix)) {
		return 0
	}

	# report status
	return 1
}
