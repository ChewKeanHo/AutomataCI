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
function FS-Append-File {
	param (
		[string]$___target,
		[string]$___content
	)


	# validate target
	if ([string]::IsNullOrEmpty($___target)) {
		return 1
	}


	# perform file write
	$null = Add-Content -Path $___target -Value $___content -NoNewline
	if ($?) {
		return 0
	}


	# report status
	return 1
}




function FS-Copy-All {
	param (
		[string]$___source,
		[string]$___destination
	)


	# validate input
	if ([string]::IsNullOrEmpty($___source) -or [string]::IsNullOrEmpty($___destination)) {
		return 1
	}


	# execute
	$null = Copy-Item -Path "${___source}\*" -Destination "${___destination}" -Recurse
	if ($?) {
		return 0
	}


	# report status
	return 1
}




function FS-Copy-File {
	param (
		[string]$___source,
		[string]$___destination
	)


	# validate input
	if ([string]::IsNullOrEmpty($___source) -or [string]::IsNullOrEmpty($___destination)) {
		return 1
	}


	# execute
	$null = Copy-Item -Path "${___source}" -Destination "${___destination}"
	if ($?) {
		return 0
	}


	# report status
	return 1
}




function FS-Extension-Remove {
	param (
		[string]$___target,
		[string]$___extension
	)


	# execute
	return FS-Extension-Replace "${___target}" "${___extension}" ""
}




function FS-Extension-Replace {
	param (
		[string]$___path,
		[string]$___extension,
		[string]$___candidate
	)


	# validate input
	if ([string]::IsNullOrEmpty($___path)) {
		return ""
	}


	# execute
	## prepare working parameters
	$___target = Split-Path -Leaf "${___path}"

	if ($___extension -eq "*") {
		## trim all extensions to the first period
		$___target = $___target -replace '(\.\w+)+$'

		## restore directory pathing when available
		if (-not [string]::IsNullOrEmpty($(Split-Path -Parent "${___path}"))) {
			$___target = $(Split-Path -Parent "${___path}") + "\" + "${___target}"
		}
	} elseif (-not [string]::IsNullOrEmpty($___extension)) {
		## trim off existing extension
		if ($___extension.Substring(0,1) -eq ".") {
			$___extension = $___extension.Substring(1)
		}
		$___target = $___target -replace "\.${___extension}$"

		## append new extension when available
		if ($___target -ne $___path) {
			if (-not [string]::IsNullOrEmpty($___candidate)) {
				if ($___candidate.Substring(0,1) -eq ".") {
					$___target += "." + $___candidate.Substring(1)
				} else {
					$___target += "." + $___candidate
				}
			}
		}

		## restore directory pathing when available
		if (-not [string]::IsNullOrEmpty($(Split-Path -Parent "${___path}"))) {
			$___target = $(Split-Path -Parent "${___path}") + "\" + "${___target}"
		}
	} else {
		## do nothing
		$___target = $___path
	}


	# report status
	return $___target
}




function FS-Get-Directory {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return ""
	}


	# execute
	return "$(Split-Path -Parent -Path "${___target}")"
}




function FS-Get-File {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return ""
	}


	# execute
	return "$(Split-Path -Leaf -Path "${___target}")"
}




function FS-Get-MIME {
	param(
		[string]$___target
	)


	# validate input
	if ((FS-Is-Target-Exist $___target) -ne 0) {
		return ""
	}


	# execute
	$___process = FS-Is-Directory "${___target}"
	if ($___process -eq 0) {
		return "inode/directory"
	}


	switch ((Get-ChildItem $___target).Extension.ToLower()) {
	".avif" {
		return "image/avif"
	} ".gif" {
		return "image/gif"
	} ".gzip" {
		return "application/x-gzip"
	} { $_ -in ".jpg", ".jpeg" } {
		return "image/jpeg"
	} ".json" {
		return "application/json"
	} ".mkv" {
		return "video/mkv"
	} ".mp4" {
		return "video/mp4"
	} ".png" {
		return "image/png"
	} ".rar" {
		return "application/x-rar-compressed"
	} ".tiff" {
		return "image/tiff"
	} ".webp" {
		return "image/webp"
	} ".xml" {
		return "application/xml"
	} ".zip" {
		return "application/zip"
	} default {
		return ""
	}}
}




function FS-Get-Path-Relative {
	param (
		[string]$___target,
		[string]$___base
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target) -or [string]::IsNullOrEmpty($___base)) {
		return ""
	}


	# execute
	$___output = Resolve-Path -Relative -Path "${___target}" -RelativeBasePath "${___base}"
	if ($___output.StartsWith(".\")) {
		$___output = $___output.Substring(2)
	}


	# report status
	return $___output
}




function FS-Is-Directory {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return 1
	}


	# execute
	if (Test-Path -Path "${___target}" -PathType Container -ErrorAction SilentlyContinue) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-File {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return 1
	}


	# execute
	$___process = FS-Is-Directory "${___target}"
	if ($___process -eq 0) {
		return 1
	}

	if (Test-Path -Path "${___target}" -ErrorAction SilentlyContinue) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-Cargo {
	param (
		[string]$___target
	)


	# execute
	if (($("${___target}" -replace '^.*-cargo') -ne "${___target}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-Chocolatey {
	param (
		[string]$___target
	)


	# execute
	if (($("${___target}" -replace '^.*-chocolatey') -ne "${___target}") -or
		($("${___target}" -replace '^.*-choco') -ne "${___target}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-Citation-CFF {
	param (
		[string]$___target
	)


	# execute
	if ($("${___target}" -replace '^.*.cff') -ne "${___target}") {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-Docs {
	param (
		[string]$___target
	)


	# execute
	if (($("${___target}" -replace '^.*-doc') -ne "${___target}") -or
		($("${___target}" -replace '^.*-docs') -ne "${___target}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-Homebrew {
	param (
		[string]$___target
	)


	# execute
	if (($("${___target}" -replace '^.*-homebrew') -ne "${___target}") -or
		($("${___target}" -replace '^.*-brew') -ne "${___target}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-Library {
	param (
		[string]$___subject
	)


	# execute
	if (($("${___subject}" -replace '^lib.*') -ne "${___subject}") -or
		($("${___subject}" -replace '.*\.a$') -ne "${___subject}") -or
		($("${___subject}" -replace '.*\.dll$') -ne "${___subject}") -or
		($("${___subject}" -replace '^.*-lib') -ne "${___subject}") -or
		($("${___subject}" -replace '^.*-libs') -ne "${___subject}") -or
		($("${___subject}" -replace '^.*-library') -ne "${___subject}") -or
		($("${___subject}" -replace '^.*-libraries') -ne "${___subject}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-MSI {
	param (
		[string]$___target
	)


	# execute
	if (($("${___target}" -replace '^.*-msi') -ne "${___target}") -or
		($("${___target}" -replace '^.*.msi') -ne "${___target}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-NPM {
	param (
		[string]$___target
	)


	# execute
	if ($("${___target}" -replace '^.*_js-js.tgz') -ne "${___target}") {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-Nupkg {
	param (
		[string]$___target
	)


	# execute
	if ($("${___target}" -replace '^.*.nupkg') -ne "${___target}") {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-PDF {
	param (
		[string]$___target
	)


	# execute
	if ($("${___target}" -replace '^.*.pdf') -ne "${___target}") {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-PYPI {
	param (
		[string]$___target
	)


	# execute
	if ($("${___target}" -replace '^.*-pypi') -ne "${___target}") {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-Source {
	param (
		[string]$___target
	)


	# execute
	if (($("${___target}" -replace '^.*-src') -ne "${___target}") -or
		($("${___target}" -replace '^.*-source') -ne "${___target}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-TARGZ {
	param (
		[string]$___target
	)


	# execute
	if (($("${___target}" -replace '^.*.tar.gz') -ne "${___target}") -or
		($("${___target}" -replace '^.*.tgz') -ne "${___target}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-TARXZ {
	param (
		[string]$___target
	)


	# execute
	if (($("${___target}" -replace '^.*.tar.xz') -ne "${___target}") -or
		($("${___target}" -replace '^.*.txz') -ne "${___target}")) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-WASM {
	param (
		[string]$___target
	)


	# execute
	if ($("${___target}" -replace '^.*-wasm') -ne "${___target}") {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-WASM-JS {
	param (
		[string]$___target
	)


	# execute
	if ($("${___target}" -replace '^.*-wasm') -eq "${___target}") {
		return 1
	}

	if ($("${___target}" -replace '^.*.js') -eq "${___target}") {
		return 1
	}


	# report status
	return 0
}




function FS-Is-Target-Exist {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty("${___target}")) {
		return 1
	}


	# perform checking
	$___process = Test-Path -Path "${___target}" -PathType Any -ErrorAction SilentlyContinue
	if ($___process) {
		return 0
	}


	# report status
	return 1
}




function FS-Is-Target-A-ZIP {
	param (
		[string]$___target
	)


	# execute
	if ($("${___target}" -replace '^.*.zip') -ne "${___target}") {
		return 0
	}


	# report status
	return 1
}




function FS-List-All {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty("${___target}")) {
		return 1
	}


	# execute
	if ((FS-Is-Directory "${___target}") -ne 0) {
		return 1
	}

	try {
		foreach ($___item in (Get-ChildItem -Path "${___target}" -Recurse)) {
			Write-Host $___item.FullName
		}

		return 0
	} catch {
		return 1
	}
}




function FS-Make-Directory {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty("${___target}")) {
		return 1
	}

	$___process = FS-Is-Directory "${___target}"
	if ($___process -eq 0) {
		return 0
	}

	$___process = FS-Is-Target-Exist "${___target}"
	if ($___process -eq 0) {
		return 1
	}


	# execute
	$___process = New-Item -ItemType Directory -Force -Path "${___target}"
	if ($___process) {
		return 0
	}


	# report status
	return 1
}




function FS-Make-Housing-Directory {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return 1
	}

	$___process = FS-Is-Directory $___target
	if ($___process -eq 0) {
		return 0
	}


	# perform create
	$___process = FS-Make-Directory (Split-Path -Parent -Path $___target)


	# report status
	return $__process
}




function FS-Move {
	param (
		[string]$___source,
		[string]$___destination
	)


	# validate input
	if ([string]::IsNullOrEmpty($___source) -or [string]::IsNullOrEmpty($___destination)) {
		return 1
	}


	# execute
	try {
		Move-Item -Path $___source -Destination $___destination -Force
		if (!$?) {
			return 1
		}
	} catch {
		return 1
	}


	# report status
	return 0
}




function FS-Remake-Directory {
	param (
		[string]$___target
	)


	# execute
	$null = FS-Remove-Silently "${___target}"
	$___process = FS-Make-Directory "${___target}"
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function FS-Remove {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return 1
	}


	# execute
	$___process = Remove-Item $___target -Force -Recurse
	if ($___process -eq $null) {
		return 0
	}


	# report status
	return 1
}




function FS-Remove-Silently {
	param (
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return 0
	}


	# execute
	$null = Remove-Item $___target -Force -Recurse -ErrorAction SilentlyContinue


	# report status
	return 0
}




function FS-Rename {
	param (
		[string]$___source,
		[string]$___target
	)


	# execute
	return FS-Move "${___source}" "${___target}"
}




function FS-Touch-File {
	param(
		[string]$___target
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___process = New-Item -Path "${___target}"
	if ($___process) {
		return 0
	}


	# report status
	return 1
}




function FS-Write-File {
	param (
		[string]$___target,
		[string]$___content
	)


	# validate input
	if ([string]::IsNullOrEmpty($___target)) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -eq 0) {
		return 1
	}


	# perform file write
	$null = Set-Content -Path $___target -Value $___content -NoNewline
	if ($?) {
		return 0
	}


	# report status
	return 1
}
