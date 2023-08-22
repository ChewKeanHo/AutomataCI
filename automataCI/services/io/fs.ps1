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
function FS-Copy-File {
	param (
		[string]$Source,
		[string]$Destination
	)

	Copy-Item -Path $Source -Destination $Destination
	if ($?) {
		return 0
	}
	return 1
}

function FS-IsDirectory {
	param (
		[string]$Subject
	)

	return Test-Path -Path $Subject -PathType Container
}

function FS-IsExists {
	param (
		[string]$Subject
	)

	return Test-Path -Path $Subject
}

function FS-List-All {
	param (
		[string]$Target
	)

	if (-not (FS-IsDirectory $Target)) {
		return 1
	}

	try {
		$items = Get-ChildItem -Path $Target -Recurse
		foreach ($item in $items) {
			Write-Host $item.FullName
		}
		return 0
	} catch {
		return 1
	}
}

function FS-Remove {
	param (
		[string]$Target
	)

	$process = Remove-Item $Target -Force -Recurse
	if ($process -eq $null) {
		return 0
	}
	return 1
}

function FS-Remove-Silently {
	param (
		[string]$Target
	)

	Remove-Item $Target -Force -Recurse -ErrorAction SilentlyContinue
	return 0
}

function FS-Rename {
	param (
		[string]$Source,
		[string]$Target
	)

	$process = Move-Item -Path $Source -Destination $Target
	if ($?) {
		return 0
	}
	return 1
}

function FS-Make-Directory {
	param (
		[string]$Target
	)

	$process = New-Item -ItemType Directory -Force -Path $Target
	if ($process) {
		return 0
	}
	return 1
}

function FS-Remake-Directory {
	param (
		[string]$Target
	)

	$process = FS-Remove-Silently $Target
	$process = FS-Make-Directory $Target
	if ($process -eq 0) {
		return 0
	}
	return 1
}
