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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function COPYRIGHT-Create {
	param (
		[string]$___location,
		[string]$___manual_file,
		[string]$___sku,
		[string]$___name,
		[string]$___email,
		[string]$___website
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___location}") -eq 0) -or
		($(STRINGS-Is-Empty "${___manual_file}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0) -or
		($(STRINGS-Is-Empty "${___name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___email}") -eq 0) -or
		($(STRINGS-Is-Empty "${___website}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___location}"
	if ($___process -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___manual_file}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___location}"
	if ($___process -eq 0) {
		return 0
	}

	# create housing directory path
	$null = FS-Make-Housing-Directory "${___location}"


	# create copyright stanza header
	$___process = FS-Write-File "${___location}" @"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${___sku}
Upstream-Contact: ${___name} <${___email}>
Source: ${___website}

"@
	if ($___process -ne 0) {
		return 1
	}


	# append manually facilitated copyright contents
	foreach ($___line in (Get-Content -Path $___manual_file)) {
		$null = FS-Append-File "${___location}" "${___line}`n"
	}


	# report status
	return 0
}
