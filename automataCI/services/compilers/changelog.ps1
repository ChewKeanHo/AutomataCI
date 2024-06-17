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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\compress\gz.ps1"




function CHANGELOG-Assemble-DEB {
	param (
		[string]$___directory,
		[string]$___target,
		[string]$___version
	)

	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0)) {
		return 1
	}

	$___directory = "${___directory}\deb"
	$___target = $___target -replace '\.gz.*$'


	# assemble file
	$null = FS-Remove-Silently "${___target}"
	$null = FS-Remove-Silently "${___target}.gz"
	$null = FS-Make-Housing-Directory "${___target}"

	$___initiated = ""
	foreach ($___line in (Get-Content "${___directory}\latest")) {
		$___process = FS-Append-File "${___target}" "${___line}`n"
		if ($___process -ne 0) {
			return 1
		}

		$___initiated = "true"
	}

	foreach ($___tag in (Invoke-Expression "git tag --sort -version:refname")) {
		$___process = FS-Is-File "${___directory}\$($___tag -replace ".*v")"
		if ($___process -ne 0) {
			continue
		}

		if ($(STRINGS-Is-Empty "${___initiated}") -eq 0) {
			$___process = FS-Append-File "${___target}" "`n`n"
			if ($___process -ne 0) {
				return 1
			}
		}

		foreach ($___line in (Get-Content "${___directory}\$($___tag -replace ".*v")")) {
			$___process = FS-Append-File "${___target}" "${___line}`n"
			if ($___process -ne 0) {
				return 1
			}

			$___initiated = "true"
		}
	}


	# gunzip
	$___process = GZ-Create "${___target}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHANGELOG-Assemble-MD {
	param (
		[string]$___directory,
		[string]$___target,
		[string]$___version,
		[string]$___title
	)

	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0) -or
		($(STRINGS-Is-Empty "${___title}") -eq 0)) {
		return 1
	}

	$___directory = "${___directory}\data"


	# assemble file
	$null = FS-Remove-Silently "${___target}"
	$null = FS-Make-Housing-Directory "${___target}"
	$null = FS-Write-File "${___target}" "# ${___title}`n`n"
	$null = FS-Append-File "${___target}" "`n## ${___version}`n`n"
	foreach ($___line in (Get-Content "${___directory}\latest")) {
		$___process = FS-Append-File "${___target}" "* ${___line}`n"
		if ($___process -ne 0) {
			return 1
		}
	}

	foreach ($___tag in (Invoke-Expression "git tag --sort -version:refname")) {
		$___process = FS-Is-File "${___directory}\$($___tag -replace ".*v")"
		if ($___process -ne 0) {
			continue
		}

		$null = FS-Append-File "${___target}" "`n`n## ${___tag}`n`n"
		foreach ($___line in (Get-Content "${___directory}\$($___tag -replace ".*v")")) {
			$___process = FS-Append-File "${___target}" "* ${___line}`n"
			if ($___process -ne 0) {
				return 1
			}
		}
	}


	# report status
	return 0
}




function CHANGELOG-Assemble-RPM {
	param (
		[string]$___target,
		[string]$___resources,
		[string]$___date,
		[string]$___name,
		[string]$___email,
		[string]$___version,
		[string]$___cadence
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___resources}") -eq 0) -or
		($(STRINGS-Is-Empty "${___date}") -eq 0) -or
		($(STRINGS-Is-Empty "${___name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___email}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0) -or
		($(STRINGS-Is-Empty "${___cadence}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___resources}"
	if ($___process -ne 0) {
		return 1
	}


	# emit stanza
	$___process = FS-Write-File "${___target}" "%%changelog`n"
	if ($___process -ne 0) {
		return 1
	}


	# emit latest changelog
	$___process = FS-Is-File "${__resources}\changelog\data\latest"
	if ($___process -eq 0) {
		$___process = FS-Append-File "${___target}" `
			"* ${___date} ${___name} <${___email}> - ${___version}-${___cadence}`n`n"
		if ($___process -ne 0) {
			return 1
		}

		foreach ($___line in (Get-Content -Path "${___directory}\changelog\data\latest")) {
			$___line = $___line -replace '#.*'
			if ($(STRINGS-Is-Empty "${___line}") -eq 0) {
				continue
			}

			$___process = FS-Append-File "${___target}" "- ${___line}`n"
			if ($___process -ne 0) {
				return 1
			}
		}
	} else {
		$___process = FS-Append-File "${___target}" "# unavailable`n"
		if ($___process -ne 0) {
			return 1
		}
	}


	# emit tailing newline
	$___process = FS-Append-File "${___target}" "`n"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHANGELOG-Build-DATA-Entry {
	param(
		[string]$___directory
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___directory}") -eq 0) {
		return 1
	}


	# get last tag from git log
	$___tag = Invoke-Expression "git rev-list --tags --max-count=1"
	if ($(STRINGS-Is-Empty "${___tag}") -eq 0) {
		$___tag = Invoke-Expression "git rev-list --max-parents=0 --abbrev-commit HEAD"
	}


	# generate log file from the latest to the last tag
	$___directory = "${___directory}\data"
	$null = FS-Make-Directory "${___directory}"
	Invoke-Expression "git log --pretty=`"%s`" HEAD...${___tag}" `
		| Out-File -FilePath "${___directory}\.latest" -Encoding utf8
	$___process = FS-Is-File "${___directory}\.latest"
	if ($___process -ne 0) {
		return 1
	}


	# good file, update the previous
	$null = FS-Remove-Silently "${___directory}\latest"
	$___process = FS-Move "${___directory}\.latest" "${___directory}\latest"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHANGELOG-Build-DEB-Entry {
	param (
		[string]$___directory,
		[string]$___version,
		[string]$___sku,
		[string]$___dist,
		[string]$___urgency,
		[string]$___name,
		[string]$___email,
		[string]$___date
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0) -or
		($(STRINGS-Is-Empty "${___dist}") -eq 0) -or
		($(STRINGS-Is-Empty "${___urgency}") -eq 0) -or
		($(STRINGS-Is-Empty "${___name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___email}") -eq 0) -or
		($(STRINGS-Is-Empty "${___date}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___directory}\data\latest"
	if ($___process -ne 0) {
		return 1
	}

	$___dest = $___dest -replace "\/.*$", ""


	# all good. Generate the log fragment
	$null = FS-Make-Directory "${___directory}\deb"


	# create the entry header
	$null = FS-Remove-Silently "${___directory}\deb\.latest"
	$null = FS-Write-File "${___directory}\deb\.latest" @"
${___sku} (${___version}) ${___dist}; urgency=${___urgency}

"@


	# generate body line-by-line
	foreach ($___line in (Get-Content -Path "${___directory}\data\latest")) {
		$___line = $___line.Substring(0, [Math]::Min($___line.Length, 80))
		$null = FS-Append-File "${___directory}\deb\.latest" "  * ${___line}`n"
	}
	$null = FS-Append-File "${___directory}\deb\.latest" ""


	# create the entry sign-off
	$null = FS-Append-File "${___directory}\deb\.latest" `
		"-- ${___name} <${___email}>  ${___date}`n"


	# good file, update the previous
	$___process = FS-Move "${___directory}\deb\.latest" "${___directory}\deb\latest"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHANGELOG-Compatible-DATA-Version {
	param(
		[string]$___directory,
		[string]$___version
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0)) {
		return 1
	}


	# execute
	$___process = FS-Is-File "${___directory}\data\${___version}"
	if ($___process -ne 0) {
		return 0
	}


	# report status
	return 1
}




function CHANGELOG-Compatible-DEB-Version {
	param(
		[string]$___directory,
		[string]$___version
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0)) {
		return 1
	}


	# execute
	$___process = FS-Is-File "${___directory}\deb\${___version}"
	if ($___process -ne 0) {
		return 0
	}


	# report status
	return 1
}




function CHANGELOG-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "git"
	if ($___process -ne 0) {
		return 1
	}

	$___process = GZ-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function CHANGELOG-Seal {
	param (
		[string]$___directory,
		[string]$___version
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory}\data\latest"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-File "${___directory}\deb\latest"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = FS-Move "${___directory}\data\latest" "${___directory}\data\${___version}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Move "${___directory}\deb\latest" "${___directory}\deb\${___version}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
