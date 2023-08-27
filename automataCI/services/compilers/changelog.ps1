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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\archive\tar.ps1"




function CHANGELOG-Is-Available {
	$_program = Get-Command git -ErrorAction SilentlyContinue
	if (-not ($_program)) {
		return 1
	}

	return 0
}




function CHANGELOG-Build-Data-Entry {
	param(
		[string]$__directory
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory)) {
		Remove-Variable -Name "__directory"
		return 1
	}

	# get last tag from git log
	$__tag = Invoke-Expression "git rev-list --tags --max-count=1"
	if ([string]::IsNullOrEmpty($__tag)) {
		$__tag = Invoke-Expression "git rev-list --max-parents=0 --abbrev-commit HEAD"
	}

	# generate log file from the latest to the last tag
	$__directory = "${__directory}\data"
	$null = New-Item -ItemType Directory -Path "$__directory" -Force
	Invoke-Expression "git log --pretty=oneline HEAD...${__tag}" `
		| Out-File -FilePath "${__directory}\.latest" -Encoding utf8
	get-content "${__directory}\.latest"
	if (-not (Test-Path "${__directory}\.latest")) {
		Remove-Variable -Name "__directory"
		Remove-Variable -Name "__tag"
		return 1
	}

	# good file, update the previous
	$null = Remove-Item "${__directory}\latest" `
		-Recurse `
		-Force `
		-ErrorAction SilentlyContinue
	$null = Move-Item -Path "${__directory}\.latest" `
			-Destination "${__directory}\latest" `
			-Force
	$__exit = $?

	# report verdict
	$null = Remove-Variable -Name "__directory"
	$null = Remove-Variable -Name "__tag"
	if ($__exit) {
		return 0
	}
	return 1
}

function CHANGELOG-Build-DEB-Entry {
	param (
		[string]$__directory,
		[string]$__version,
		[string]$__sku,
		[string]$__dist,
		[string]$__urgency,
		[string]$__name,
		[string]$__email,
		[string]$__date
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__version) -or
		(-not (Test-Path -Path "${__directory}\data\latest")) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__dist) -or
		[string]::IsNullOrEmpty($__urgency) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__date)) {
		$null = Remove-Variable -Name "__directory"
		$null = Remove-Variable -Name "__version"
		$null = Remove-Variable -Name "__sku"
		$null = Remove-Variable -Name "__dist"
		$null = Remove-Variable -Name "__urgency"
		$null = Remove-Variable -Name "__name"
		$null = Remove-Variable -Name "__email"
		$null = Remove-Variable -Name "__date"
		return 1
	}


	switch ($__dist) {
	stable {
		break
	} unstable {
		break
	} testing {
		break
	} experimental {
		break
	} default {
		$null = Remove-Variable -Name "__directory"
		$null = Remove-Variable -Name "__version"
		$null = Remove-Variable -Name "__sku"
		$null = Remove-Variable -Name "__dist"
		$null = Remove-Variable -Name "__urgency"
		$null = Remove-Variable -Name "__name"
		$null = Remove-Variable -Name "__email"
		$null = Remove-Variable -Name "__date"
		return 1
	}}

	# all good. Generate the log fragment
	$null = New-Item -ItemType Directory -Path "${__directory}\deb" -Force

	# create the entry header
	"${__sku} (${__version}) ${__dist}; urgency=${__urgency}" `
		| Out-File -FilePath "${__directory}\deb\.latest" -Encoding utf8

	# generate body line-by-line
	"" | Out-File -FilePath "${__directory}\deb\.latest" -Encoding utf8 -Append
	Get-Content -Path "${__directory}\data\latest" | ForEach-Object {
		$__line = $_.Substring(0, [Math]::Min($_.Length, 80))
		"  * ${__line}" `
			| Out-File -FilePath "${__directory}\deb\.latest" -Encoding utf8 -Append
	}
	"" | Out-File -FilePath "${__directory}\deb\.latest" -Encoding utf8 -Append

	# create the entry sign-off
	"-- ${__name} <${__email}>  ${__date}" `
		| Out-File -FilePath "${__directory}\deb\.latest" -Encoding utf8 -Append

	# good file, update the previous
	$null = Move-Item -Path "${__directory}\deb\.latest" `
		-Destination "${__directory}\deb\latest" `
		-Force
	$__exit = $?

	# report status
	$null = Remove-Variable -Name "__directory"
	$null = Remove-Variable -Name "__version"
	$null = Remove-Variable -Name "__sku"
	$null = Remove-Variable -Name "__dist"
	$null = Remove-Variable -Name "__urgency"
	$null = Remove-Variable -Name "__name"
	$null = Remove-Variable -Name "__email"
	$null = Remove-Variable -Name "__date"
	if (!$__exit) {
		return 1
	}
	return 0
}

function CHANGELOG-Compatible-Data-Version {
	param(
		[string]$__directory,
		[string]$__version
	)

	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__version)) {
		$null = Remove-Variable -Name "__directory"
		$null = Remove-Variable -Name "__version"
		return 1
	}

	if (-not (Test-Path -Path "${__directory}\data\${__version}")) {
		$null = Remove-Variable -Name "__directory"
		$null = Remove-Variable -Name "__version"
		return 0
	}

	return 1
}

function CHANGELOG-Compatible-DEB-Version {
	param(
		[string]$__directory,
		[string]$__version
	)

	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__version)) {
		$null = Remove-Variable -Name "__directory"
		$null = Remove-Variable -Name "__version"
		return 1
	}

	if (-not (Test-Path -Path "${__directory}\deb\${__version}")) {
		$null = Remove-Variable -Name "__directory"
		$null = Remove-Variable -Name "__version"
		return 0
	}

	return 1
}

function CHANGELOG-Assemble-DEB {
	param (
		[string]$__directory,
		[string]$__target,
		[string]$__version
	)

	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__version)) {
		$null = Remove-Variable -Name "__directory"
		$null = Remove-Variable -Name "__target"
		$null = Remove-Variable -Name "__version"
		return 1
	}
	$__directory = "${__directory}\deb"

	# assemble file
	$null = Remove-Item -Path $__target, "${__target}.gz" -ErrorAction SilentlyContinue
	$null = New-Item -ItemType Directory -Path (Split-Path ${__target}) -Force

	foreach ($__line in (Get-Content -Path "${__directory}\latest")) {
		"${__line}" | Out-File -FilePath $__target -Encoding utf8 -Append
	}

	git tag --sort version:refname | ForEach-Object {
		$__line = $_
		if (-not (Test-Path "${__directory}\${__line}")) {
			continue
		}

		Get-Content "${__directory}\${__line}" | ForEach-Object {
			"$`n$_" | Out-File -FilePath $__target -Encoding utf8 -Append
		}
	}
	$null = Remove-Variable -Name "__line"

	# gunzip
	$process = GZ-Create "${__target}" "${__target}.gz"

	# report status
	$null = Remove-Variable -Name "__directory"
	$null = Remove-Variable -Name "__target"
	$null = Remove-Variable -Name "__version"
	return $process
}




function CHANGELOG-Assemble-MD {
	param(
		[string]$__directory,
		[string]$__target,
		[string]$__version
	)

	# report status
	$null = Remove-Variable -Name "__directory"
	$null = Remove-Variable -Name "__target"
	$null = Remove-Variable -Name "__version"
	return 0
}
