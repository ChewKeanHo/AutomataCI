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
function DISK-Calculate-Size {
	param (
		[string]$__location
	)

	# validate input
	if ([string]::IsNullOrEmpty($__location) -or (-not (Test-Path -Path "$__location"))) {
		return 1
	}

	$__process = DISK-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$__value  = Get-ChildItem ${__location} -Recurse -Force `
			-ErrorAction SilentlyContinue -Include * `
		| Where-Object {$_.psiscontainer -eq $false} `
		| Measure-Object -Property length -sum `
		| Select-Object sum
	$__value = [math]::Round($__value.sum / 1000,0)   #.ToString("#")
	return $__value
}




function DISK-Is-Available {
	return 0
}
