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
function Get-Python-Path {
	[CmdletBinding()]

	$program = Get-Command python -ErrorAction SilentlyContinue
	if ($program) {
		return $program.Source
	}

	return $null
}




function Check-Python-Available {
	[CmdletBinding()]
	Param (
	)

	$program = Get-Command python -ErrorAction SilentlyContinue
	if ($program) {
		return 0
	}

	Write-Host "[ ERROR ] - Python was not installed. Please install.!\n"
	return 1
}
