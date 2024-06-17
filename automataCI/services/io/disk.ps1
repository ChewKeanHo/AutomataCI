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
function DISK-Calculate-Size-Directory-KB {
	param (
		[string]$___directory
	)


	# validate input
	if ([string]::IsNullOrEmpty($___directory) -or
		(-not (Test-Path -Path "${___directory}"))) {
		return 1
	}

	$___process = DISK-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___value  = Get-ChildItem "${___directory}" -Recurse -Force `
			-ErrorAction SilentlyContinue -Include * `
		| Where-Object {$_.psiscontainer -eq $false} `
		| Measure-Object -Property length -sum `
		| Select-Object sum
	return [math]::Round($___value.sum / 1000,0)
}




function DISK-Calculate-Size-File-Byte {
	param (
		[string]$___file
	)


	# validate input
	if ([string]::IsNullOrEmpty($___file) -or (-not (Test-Path -Path "${___file}"))) {
		return 1
	}

	$___process = DISK-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___value  = Get-ChildItem $___file `
		| Measure-Object -Property length -Sum `
		| Select-Object sum
	return [math]::Round($___value.sum / 1, 0)
}




function DISK-Is-Available {
	return 0
}
