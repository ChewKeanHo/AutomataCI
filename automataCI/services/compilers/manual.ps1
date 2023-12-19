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
. "${env:LIBS_AUTOMATACI}\services\compress\gz.ps1"




function MANUAL-Create {
	param(
		[string]$___location,
		[string]$___sku,
		[string]$___name,
		[string]$___email,
		[string]$___website
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___location}") -eq 0) -or
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


	# create housing directory path
	$null = FS-Make-Housing-Directory "${___location}"
	$null = FS-Remove-Silently "${___location}"
	$null = FS-Remove-Silently "${___location}.gz"


	# create basic level 1 man page that instruct users to seek --help
	$___process = FS-Write-File "${___location}" @"
.`" ${___sku} - Lv1 Manpage
.TH man 1 `"${___sku} man page`"

.SH NAME
${___sku} - Getting help

.SH SYNOPSIS
command: $ ./${___sku} help

.SH DESCRIPTION
This is a backward-compatible auto-generated system-level manual page. To make
sure you get the required and proper assistances from the software, please make
sure you call the command above.

.SH SEE ALSO
Please visit ${___website} for more info.

.SH AUTHORS
Contact: ${___name} <${___email}>
"@
	if ($___process -ne 0) {
		return 0
	}


	# gunzip the manual
	$___process = GZ-Create "${___location}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function MANUAL-Is-Available {
	# execute
	$___process = GZ-Is-Available
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}
