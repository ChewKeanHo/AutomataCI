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




function CITATION-Build {
	param(
		[string]$___filepath,
		[string]$___abstract_filepath,
		[string]$___citation_filepath,
		[string]$___cff_version,
		[string]$___type,
		[string]$___date,
		[string]$___title,
		[string]$___version,
		[string]$___license,
		[string]$___repo,
		[string]$___repo_code,
		[string]$___repo_artifact,
		[string]$___contact_name,
		[string]$___contact_website,
		[string]$___contact_email
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___cff_version}") -eq 0) {
		return 0 # requested to be disabled
	}

	if (($(STRINGS-Is-Empty "${___filepath}") -eq 0) -or
		($(STRINGS-Is-Empty "${___title}") -eq 0) -or
		($(STRINGS-Is-Empty "${___type}") -eq 0)) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${___citation_filepath}") -eq 0) {
		return 1
	}

	$___process = FS-Is-File "${___citation_filepath}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Remove-Silently "${___filepath}"
	$null = FS-Make-Housing-Directory "${___filepath}"
	$___process = FS-Write-File "${___filepath}" @"
# WARNING: auto-generated by AutomataCI

cff-version: `"${___cff_version}`"
type: `"${___type}`"
"@
	if ($___process -ne 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${___date}") -ne 0) {
		$___process = FS-Append-File "${___filepath}" @"
date-released: `"${___date}`"
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${___title}") -ne 0) {
		$___process = FS-Append-File "${___filepath}" @"
title: `"${___title}`"
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${___version}") -ne 0) {
		$___process = FS-Append-File "${___filepath}" @"
version: `"${___version}`"
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${___license}") -ne 0) {
		$___process = FS-Append-File "${___filepath}" @"
license: `"${___license}`"
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${___repo}") -ne 0) {
		$___process = FS-Append-File "${___filepath}" @"
repository: `"${___repo}`"
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${___repo_code}") -ne 0) {
		$___process = FS-Append-File "${___filepath}" @"
repository-code: `"${___repo_code}`"
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${___repo_artifact}") -ne 0) {
		$___process = FS-Append-File "${___filepath}" @"
repository-artifact: `"${___repo_artifact}`"
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${___contact_website}") -ne 0) {
		$___process = FS-Append-File "${___filepath}" @"
url: `"${___contact_website}`"
"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${___contact_name}") -ne 0) {
		if (($(STRINGS-Is-Empty "${___contact_website}") -ne 0) -or
			($(STRINGS-Is-Empty "${___contact_email}") -ne 0)) {
			$___process = FS-Append-File "${___filepath}" @"
contact:
  - affiliation: `"${___contact_name}`"
"@
			if ($___process -ne 0) {
				return 1
			}

			if ($(STRINGS-Is-Empty "${___contact_email}") -ne 0) {
				$___process = FS-Append-File "${___filepath}" @"
    email: `"${___contact_email}`"
"@
				if ($___process -ne 0) {
					return 1
				}
			}

			if ($(STRINGS-Is-Empty "${___contact_website}") -ne 0) {
				$___process = FS-Append-File "${___filepath}" @"
    website: `"${__contact_website}`"
"@
				if ($___process -ne 0) {
					return 1
				}
			}
		}
	}

	$___process = FS-Is-File "${___abstract_filepath}"
	if ($___process -eq 0) {
		$___process = FS-Append-File "${___filepath}" @"
abstract: |-
"@
		if ($___process -ne 0) {
			return 1
		}

		foreach ($___line in (Get-Content "${___abstract_filepath}")) {
			if (($(STRINGS-Is-Empty "${___line}") -ne 0) -and
				($(STRINGS-Is-Empty "$($___line -replace "#.*$")") -eq 0)) {
				continue
			}

			$___line = $___line -replace '#.*'
			if ($(STRINGS-Is-Empty "${___line}") -ne 0) {
				$___line = "  ${___line}"
			}

			$___process = FS-Append-File "${___filepath}" "${___line}"
			if ($___process -ne 0) {
				return 1
			}
		}
	}

	foreach ($___line in (Get-Content "${___citation_filepath}")) {
		if (($(STRINGS-Is-Empty "${___line}") -ne 0) -and
			($(STRINGS-Is-Empty "$($___line -replace "#.*$")") -eq 0)) {
			continue
		}

		$___line = $___line -replace '#.*'
		if ($(STRINGS-Is-Empty "${___line}") -ne 0) {
			continue
		}

		$___process = FS-Append-File "${___filepath}" "${___line}"
		if ($___process -ne 0) {
			return 1
		}
	}


	# report status
	return 0
}
