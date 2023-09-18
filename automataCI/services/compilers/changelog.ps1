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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compress\gz.ps1"




function CHANGELOG-Assemble-DEB {
	param (
		[string]$__directory,
		[string]$__target,
		[string]$__version
	)

	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__version)) {
		return 1
	}

	$__directory = "${__directory}\deb"
	$__target = $__target -replace '\.gz.*$'

	# assemble file
	$null = FS-Remove-Silently "${__target}"
	$null = FS-Remove-Silently "${__target}.gz"
	$null = FS-Make-Housing-Directory "${__target}"

	foreach ($__line in (Get-Content "${__directory}\latest")) {
		$__process = FS-Append-File "${__target}" "${__line}"
		if ($__process -ne 0) {
			return 1
		}
	}

	foreach ($__tag in (git tag --sort version:refname)) {
		if (-not (Test-Path "${__directory}\${__tag}")) {
			continue
		}

		foreach ($__line in (Get-Content "${__directory}\${__tag}")) {
			$__process = FS-Append-File "${__target}" "`n${__line}"
			if ($__process -ne 0) {
				return 1
			}
		}
	}

	# gunzip
	$__process = GZ-Create "${__target}"

	# report status
	return $__process
}




function CHANGELOG-Assemble-MD {
	param (
		[string]$__directory,
		[string]$__target,
		[string]$__version,
		[string]$__title
	)

	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__version) -or
		[string]::IsNullOrEmpty($__title)) {
		return 1
	}

	$__directory = "${__directory}\data"

	# assemble file
	$null = FS-Remove-Silently "${__target}"
	$null = FS-Make-Housing-Directory "${__target}"
	$null = FS-Write-File "${__target}" "# ${__title}`n"
	$null = FS-Append-File "${__target}" "`n## ${__version}`n"
	foreach ($__line in (Get-Content "${__directory}\latest")) {
		$__process = FS-Append-File "${__target}" "* ${__line}"
		if ($__process -ne 0) {
			return 1
		}
	}

	foreach ($__tag in (git tag --sort version:refname)) {
		if (-not (Test-Path "${__directory}\${__tag}")) {
			continue
		}

		$null = FS-Append-File "${__target}" "`n`n##${__tag}`n"
		foreach ($__line in (Get-Content "${__directory}\${__tag}")) {
			$__process = FS-Append-File "${__target}" "* ${__line}"
			if ($__process -ne 0) {
				return 1
			}
		}
	}

	# report status
	return $__process
}




function CHANGELOG-Assemble-RPM {
	param (
		[string]$__target,
		[string]$__resources,
		[string]$__date,
		[string]$__name,
		[string]$__email,
		[string]$__version,
		[string]$__cadence
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__resources) -or
		[string]::IsNullOrEmpty($__date) -or
		[string]::IsNullOrEmpty($__name) -or
		[string]::IsNullOrEmpty($__email) -or
		[string]::IsNullOrEmpty($__version) -or
		[string]::IsNullOrEmpty($__cadence) -or
		(-not (Test-Path -Path "${__target}")) -or
		(-not (Test-Path -Path "${__resources}" -PathType Container))) {
		return 1
	}

	# emit stanza
	$__process = FS-Write-File "${__target}" "%%changelog`n"
	if ($__process -ne 0) {
		return 1
	}

	# emit latest changelog
	if (Test-Path -Path "${__resources}\changelog\data\latest") {
		$__process = FS-Append-File "${__target}" `
			"* ${__date} ${__name} <${__email}> - ${__version}-${__cadence}`n"
		if ($__process -ne 0) {
			return 1
		}

		Get-Content -Path "${__directory}\changelog\data\latest" | ForEach-Object {
			$__line = $_ -replace '#.*'
			if ([string]::IsNullOrEmpty($__line)) {
				continue
			}

			$__process = FS-Append-File "${__target}" "  * ${__line}"
			if ($__process -ne 0) {
				return 1
			}
		}
	} else {
		$__process = FS-Append-File "${__target}" "# unavailable`n"
		if ($__process -ne 0) {
			return 1
		}
	}

	# emit tailing newline
	$__process = FS-Append-File "${__target}" "`n"

	# report status
	return $__process
}




function CHANGELOG-Build-Data-Entry {
	param(
		[string]$__directory
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory)) {
		return 1
	}

	# get last tag from git log
	$__tag = Invoke-Expression "git rev-list --tags --max-count=1"
	if ([string]::IsNullOrEmpty($__tag)) {
		$__tag = Invoke-Expression "git rev-list --max-parents=0 --abbrev-commit HEAD"
	}

	# generate log file from the latest to the last tag
	$__directory = "${__directory}\data"
	$null = FS-Make-Directory "${__directory}"
	Invoke-Expression "git log --pretty=`"%s`" HEAD...${__tag}" `
		| Out-File -FilePath "${__directory}\.latest" -Encoding utf8
	if (-not (Test-Path "${__directory}\.latest")) {
		return 1
	}

	# good file, update the previous
	$null = FS-Remove-Silently "${__directory}\latest"
	$__process = FS-Move "${__directory}\.latest" "${__directory}\latest"

	# report status
	return $__process
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
		return 1
	}}

	# all good. Generate the log fragment
	$null = FS-Make-Directory "${__directory}\deb"

	# create the entry header
	$null = FS-Write-File "${__directory}\deb\.latest" @"
${__sku} (${__version}) ${__dist}; urgency=${__urgency}

"@

	# generate body line-by-line
	Get-Content -Path "${__directory}\data\latest" | ForEach-Object {
		$__line = $_.Substring(0, [Math]::Min($_.Length, 80))
		$null = FS-Append-File "${__directory}\deb\.latest" "  * ${__line}"
	}
	$null = FS-Append-File "${__directory}\deb\.latest" ""

	# create the entry sign-off
	$null = FS-Append-File "${__directory}\deb\.latest" `
		"-- ${__name} <${__email}>  ${__date}"

	# good file, update the previous
	$__process = FS-Move "${__directory}\deb\.latest" "${__directory}\deb\latest"

	# report status
	return $__process
}




function CHANGELOG-Compatible-Data-Version {
	param(
		[string]$__directory,
		[string]$__version
	)

	if ([string]::IsNullOrEmpty($__directory) -or [string]::IsNullOrEmpty($__version)) {
		return 1
	}

	$__process = FS-Is-File "${__directory}\data\${__version}"
	if ($__process -ne 0) {
		return 0
	}

	return 1
}




function CHANGELOG-Compatible-DEB-Version {
	param(
		[string]$__directory,
		[string]$__version
	)

	if ([string]::IsNullOrEmpty($__directory) -or [string]::IsNullOrEmpty($__version)) {
		return 1
	}

	$__process = FS-Is-File "${__directory}\deb\${__version}"
	if ($__process -ne 0) {
		return 0
	}

	return 1
}




function CHANGELOG-Is-Available {
	$__program = Get-Command git -ErrorAction SilentlyContinue
	if (-not ($__program)) {
		return 1
	}

	$__process = GZ-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	return 0
}




function CHANGELOG-Seal {
	param (
		[string]$__directory,
		[string]$__version
	)

	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__version) -or
		(-not (Test-Path -Path "${__directory}" -PathType Container))) {
		return 1
	}

	if (-not (Test-Path -Path "${__directory}\data\latest")) {
		return 1
	}

	if (-not (Test-Path -Path "${__directory}\deb\latest")) {
		return 1
	}

	# execute
	$__process = FS-Move "${__directory}\data\latest" "${__directory}\data\${__version}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = FS-Move "${__directory}\deb\latest" "${__directory}\deb\${__version}"
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}
