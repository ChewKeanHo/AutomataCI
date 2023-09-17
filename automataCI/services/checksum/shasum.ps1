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
function SHASUM-Checksum-File {
	param (
		[string]$__target,
		[string]$__algo
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		(-not (Test-Path -Path "$__target")) -or
		[string]::IsNullOrEmpty($__algo)) {
		return ""
	}

	# execute
	switch ($__algo) {
	'1' {
		return (Get-FileHash -Path $__target.FullName -Algorithm SHA1).Hash
	} '224' {
		return ""
	} '256' {
		return (Get-FileHash -Path $__target.FullName -Algorithm SHA256).Hash
	} '384' {
		return (Get-FileHash -Path $__target.FullName -Algorithm SHA384).Hash
	} '512' {
		return (Get-FileHash -Path $__target.FullName -Algorithm SHA512).Hash
	} '512224' {
		return ""
	} '512256' {
		return ""
	} Default {
		return ""
	}}
}




function SHASUM-Is-Available {
	$__ret = [System.Security.Cryptography.SHA1]::Create("SHA1")
	if (-not $__ret) {
		return 1
	}

	$__ret = [System.Security.Cryptography.SHA256]::Create("SHA256")
	if (-not $__ret) {
		return 1
	}

	$__ret = [System.Security.Cryptography.SHA384]::Create("SHA384")
	if (-not $__ret) {
		return 1
	}

	$__ret = [System.Security.Cryptography.SHA512]::Create("SHA512")
	if (-not $__ret) {
		return 1
	}

	return 0
}
