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




function DOCKER-Amend-Manifest {
	param(
		[string]$___tag,
		[string]$___list
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___tag}" -eq 0) -or
		($(STRINGS-Is-Empty "${___list}") -eq 0)) {
		return 1
	}


	# execute
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = 1
	$___process = OS-Exec "docker" "manifest create `"${___tag}`" ${___list}"
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = $null
	if ($___process -ne 0) {
		return 1
	}

	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = 1
	$___process = OS-Exec "docker" "manifest push `"${___tag}`""
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = $null
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DOCKER-Check-Login {
	# validate input
	if (($(STRINGS-Is-Empty "${env:CONTAINER_USERNAME}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:CONTAINER_PASSWORD}") -eq 0)) {
		return 1
	}


	# report status
	return 0
}




function DOCKER-Clean-Up {
	# validate input
	$___process = DOCKER-Is-Available
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "docker" "system prune --force"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DOCKER-Create {
	param(
		[string]$___destination,
		[string]$___os,
		[string]$___arch,
		[string]$___repo,
		[string]$___sku,
		[string]$___version
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___destination}") -eq 0) -or
		($(STRINGS-Is-Empty "${___os}") -eq 0) -or
		($(STRINGS-Is-Empty "${___arch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___repo}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0)) {
		return 1
	}

	$___process = DOCKER-Is-Available
	if ($___process -ne 0) {
		return 1
	}

	$___dockerfile = ".\Dockerfile"
	$___tag = DOCKER-Get-ID "${___repo}" "${___sku}" "${___version}" "${___os}" "${___arch}"

	$___process = FS-Is-File "${___dockerfile}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = DOCKER-Login "${___repo}"
	if ($___process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$___arguments = "buildx build " `
			+ "--platform `"${___os}/${___arch}`" " `
			+ "--file `"${___dockerfile}`" " `
			+ "--tag `"${___tag}`" " `
			+ "--provenance=false " `
			+ "--sbom=false " `
			+ "--label `"org.opencontainers.image.ref.name=${___tag}`" " `
			+ "--push " `
			+ "."
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = 1
	$___process = OS-Exec "docker" $___arguments
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = $null
	if ($___process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$___process = DOCKER-logout
	if ($___process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$___process = FS-Append-File "${___destination}" "${___os} ${___arch} ${___tag}`n"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DOCKER-Get-Builder-ID {
	return "multiarch"
}




function DOCKER-Get-ID {
	param(
		[string]$___repo,
		[string]$___sku,
		[string]$___version,
		[string]$___os,
		[string]$___arch
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___repo}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0)) {
		return 1
	}


	# execute
	if (($(STRINGS-Is-Empty "${___os}") -ne 0) -and
		($(STRINGS-Is-Empty "${___arch}") -ne 0)) {
		return STRINGS-To-Lowercase `
			"${___repo}/${___sku}:${___os}-${___arch}_${___version}"
	} elseif (($(STRINGS-Is-Empty "${___os}") -eq 0) -and
		($(STRINGS-Is-Empty "${___arch}") -ne 0)) {
		return STRINGS-To-Lowercase `
			"${___repo}/${___sku}:${___arch}_${___version}"
	} elseif (($(STRINGS-Is-Empty "${___os}") -ne 0) -and
		($(STRINGS-Is-Empty "${___arch}") -eq 0)) {
		return STRINGS-To-Lowercase `
			"${___repo}/${___sku}:${___os}_${___version}"
	} else {
		return STRINGS-To-Lowercase "${___repo}/${___sku}:${___version}"
	}
}




function DOCKER-Is-Available {
	# execute
	$___process = OS-Is-Command-Available "docker"
	if ($___process -ne 0) {
		return 1
	}

	$null = Invoke-Expression -Command "docker ps" -ErrorAction SilentlyContinue 2> $null
	if ($LASTEXITCODE -ne 0) {
		return 1
	}

	$null = Invoke-Expression `
		-Command "docker buildx inspect `"$(DOCKER-Get-Builder-ID)`"" `
		-ErrorAction SilentlyContinue `
		2> $null
	if ($LASTEXITCODE -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DOCKER-Is-Valid {
	param (
		[string]$___target
	)


	# execute
	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	if ((Split-Path -Leaf -Path "${___target}") -eq "docker.txt") {
		return 0
	}


	# report status
	return 1
}




function DOCKER-Login {
	param(
		[string]$___repo
	)


	# validate input
	if ($(STRINGS-Is-Empty "${___repo}") -eq 0) {
		return 1
	}

	$___process = DOCKER-Check-Login
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = Write-Output "${env:CONTAINER_PASSWORD}" `
		| Start-Process -NoNewWindow `
			-FilePath "docker" `
			-ArgumentList "login --username `"${env:CONTAINER_USERNAME}`" --password-stdin" `
			-PassThru


	# report status
	if ($___process.ExitCode -eq 0) {
		return 0
	}

	return 1
}




function DOCKER-Logout {
	return OS-Exec "docker" "logout"
}




function DOCKER-Release {
	param (
		[string]$___target,
		[string]$___version
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___target}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___list = ""
	$___repo = ""
	$___sku = ""
	Get-Content -Path "${___target}" | ForEach-Object {
		if (($(STRINGS-Is-Empty "${_}") -eq 0) -or (${_} == "`n")) {
			continue
		}

		$___entry = ${_}.Substring(${_}.LastIndexOf(" ") + 1)
		$___repo = ${___entry}.Substring(0, ${___entry}.IndexOf(":"))
		$___sku = ${___repo}.Substring(${___repo}.LastIndexOf("/") + 1)
		$___repo = ${___repo}.Substring(0, ${___repo}.LastIndexOf("/"))

		if ($(STRINGS-Is-Empty "${___list}") -ne 0) {
			$___list = "${___list} "
		}

		$___list = "${___list}--amend ${___entry}"
	}

	if (($(STRINGS-Is-Empty "${___list}") -eq 0) -or
		($(STRINGS-Is-Empty "${___repo}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0)) {
		return 1
	}

	$___process = DOCKER-Login "${___repo}"
	if ($___process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$___process = DOCKER-Amend-Manifest `
		(DOCKER-Get-ID "${___repo}" "${___sku}" "latest") `
		"${___list}"
	if ($___process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$___process = DOCKER-Amend-Manifest `
		(DOCKER-Get-ID "${___repo}" "${___sku}" "${___version}") `
		"${___list}"
	if ($___process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$___process = DOCKER-Logout
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function DOCKER-Setup {
	# validate input
	$___process =  OS-Is-Command-Available "choco"
	if ($___process -ne 0) {
		return 1
	}

	$___process = DOCKER-Is-Available
	if ($___process -ne 0) {
		# NOTE: nothing else can be done since it's host-specific.
		#       DO NOT choco install Docker-Desktop autonomously.
		return 0
	}


	# execute
	$___name = DOCKER-Get-Builder-ID

	$___process = OS-Exec "docker" "buildx inspect `"${___name}`""
	if ($___process -eq 0) {
		return 0
	}

	$___process = OS-Exec "docker" "buildx create --use --name `"${___name}`""
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
