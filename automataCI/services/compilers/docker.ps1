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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"




function DOCKER-Amend-Manifest {
	param(
		[string]$__tag,
		[string]$__list
	)

	# validate input
	if ([string]::IsNullOrEmpty(${__tag}) -or [string]::IsNullOrEmpty(${__list})) {
		return 1
	}

	# execute
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = 1
	$__process = OS-Exec "docker" "manifest create `"${__tag}`" ${__list}"
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = $null
	if ($__process -ne 0) {
		return 1
	}

	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = 1
	$__process = OS-Exec "docker" "manifest push `"${__tag}`""
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = $null
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function DOCKER-Check-Login {
	# validate input
	if ([string]::IsNullOrEmpty(${env:CONTAINER_USERNAME}) -or
		[string]::IsNullOrEmpty(${env:CONTAINER_PASSWORD})) {
		return 1
	}

	# report status
	return 0
}




function DOCKER-Clean-Up {
	# validate input
	$__process = DOCKER-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$__process = OS-Exec "docker" "system prune --force"

	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function DOCKER-Create {
	param(
		[string]$__destination,
		[string]$__os,
		[string]$__arch,
		[string]$__repo,
		[string]$__sku,
		[string]$__version
	)

	# validate input
	if ([string]::IsNullOrEmpty($__destination) -or
		[string]::IsNullOrEmpty($__os) -or
		[string]::IsNullOrEmpty($__arch) -or
		[string]::IsNullOrEmpty($__repo) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__version)) {
		return 1
	}

	$__process = DOCKER-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	$__dockerfile = ".\Dockerfile"
	$__tag = DOCKER-Get-ID "${__repo}" "${__sku}" "${__version}" "${__os}" "${__arch}"

	$__process = FS-Is-File "${__dockerfile}"
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$__process = DOCKER-Login "${__repo}"
	if ($__process -ne 0) {
		return 1
	}

	$__arguments = "buildx build " `
			+ "--platform `"${__os}/${__arch}`" " `
			+ "--file `"${__dockerfile}`" " `
			+ "--tag `"${__tag}`" " `
			+ "--provenance=false " `
			+ "--sbom=false " `
			+ "--label `"org.opencontainers.image.ref.name=${__tag}`" " `
			+ "--push " `
			+ "."
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = 1
	$__process = OS-Exec "docker" $__arguments
	$env:BUILDX_NO_DEFAULT_ATTESTATIONS = $null
	if ($__process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$__process = DOCKER-logout
	if ($__process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$__process = DOCKER-Stage "${__destination}" "${__os}" "${__arch}" "${__tag}"

	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function DOCKER-Get-Builder-ID {
	return "multiarch"
}




function DOCKER-Get-ID {
	param(
		[string]$__repo,
		[string]$__sku,
		[string]$__version,
		[string]$__os,
		[string]$__arch
	)

	# validate input
	if ([string]::IsNullOrEmpty($__repo) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__version)) {
		return 1
	}

	# execute
	if ((-not [string]::IsNullOrEmpty($__os)) -and (-not [string]::IsNullOrEmpty($__arch))) {
		return STRINGS-To-Lowercase "${__repo}/${__sku}:${__os}-${__arch}_${__version}"
	} elseif ([string]::IsNullOrEmpty($__os) -and (-not [string]::IsNullOrEmpty($__arch))) {
		return STRINGS-To-Lowercase "${__repo}/${__sku}:${__arch}_${__version}"
	} elseif ((-not [string]::IsNullOrEmpty($__os)) -and [string]::IsNullOrEmpty($__arch)) {
		return STRINGS-To-Lowercase "${__repo}/${__sku}:${__os}_${__version}"
	}
}




function DOCKER-Is-Available {
	# execute
	$__process = OS-Is-Command-Available "docker"
	if ($__process -ne 0) {
		return 1
	}

	$null = Invoke-Expression `
		-Command "docker ps" `
		-ErrorAction SilentlyContinue `
		2> $null
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
		[string]$__target
	)

	# execute
	if (-not (Test-Path -PathType Leaf -Path "${__target}")) {
		return 1
	}

	$__output = Split-Path -Leaf -Path "${__target}"
	if (${__output} -eq "docker.txt") {
		return 0
	}

	# report status
	return 1
}




function DOCKER-Login {
	param(
		[string]$__repo
	)

	# validate input
	if ([string]::IsNullOrEmpty($__repo)) {
		return 1
	}

	$__process = DOCKER-Check-Login
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$__process = Write-Output "${env:CONTAINER_PASSWORD}" `
		| Start-Process -NoNewWindow `
			-FilePath "docker" `
			-ArgumentList "login --username `"${env:CONTAINER_USERNAME}`" --password-stdin" `
			-PassThru

	# report status
	if ($__process.ExitCode -eq 0) {
		return 0
	}

	return 1
}




function DOCKER-Logout {
	return OS-Exec "docker" "logout"
}




function DOCKER-Release {
	param (
		[string]$__target,
		[string]$__directory,
		[string]$__datastore,
		[string]$__version
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__datastore) -or
		(-not (Test-Path -Path "${__target}")) -or
		(-not (Test-Path -Path "${__directory}" -PathType Container)) -or
		(-not (Test-Path -Path "${__datastore}" -PathType Container))) {
		return 1
	}

	# execute
	$__list = ""
	$__repo = ""
	$__sku = ""

	Get-Content -Path "${__target}" | ForEach-Object {
		if ([string]::IsNullOrEmpty(${_}) -or (${_} == "`n")) {
			continue
		}

		$__entry = ${_}.Substring(${_}.LastIndexOf(" ") + 1)
		$__repo = ${__entry}.Substring(0, ${__entry}.IndexOf(":"))
		$__sku = ${__repo}.Substring(${__repo}.LastIndexOf("/") + 1)
		$__repo = ${__repo}.Substring(0, ${__repo}.LastIndexOf("/"))

		if (-not ([string]::IsNullOrEmpty($__list))) {
			$__list = "${__list} "
		}

		$__list = "${__list}--amend $__entry"
	}

	if ([string]::IsNullOrEmpty($__list) -or
		[string]::IsNullOrEmpty($__repo) -or
		[string]::IsNullOrEmpty($__sku)) {
		return 1
	}

	$__process = DOCKER-Login "${__repo}"
	if ($__process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$__process = DOCKER-Amend-Manifest `
		(DOCKER-Get-ID "${__repo}" "${__sku}" "latest") `
		"${__list}"
	if ($__process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$__process = DOCKER-Amend-Manifest `
		(DOCKER-Get-ID "${__repo}" "${__sku}" "${__version}") `
		"${__list}"
	if ($__process -ne 0) {
		$null = DOCKER-Logout
		return 1
	}

	$__process = DOCKER-Logout
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function DOCKER-Setup-Builder-MultiArch {
	# validate input
	$__process = DOCKER-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$__name = DOCKER-Get-Builder-ID

	$__process = OS-Exec "docker" "buildx inspect `"${__name}`""
	if ($__process -eq 0) {
		return 0
	}

	$__process = OS-Exec "docker" "buildx create --use --name `"${__name}`""
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function DOCKER-Stage {
	param (
		[string]$__target,
		[string]$__os,
		[string]$__arch,
		[string]$__tag
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__os) -or
		[string]::IsNullOrEmpty($__arch) -or
		[string]::IsNullOrEmpty($__tag)) {
		return 1
	}

	# execute
	$__process = FS-Append-File "${__target}" @"
${__os} ${__arch} ${__tag}`n
"@

	# report status
	return 0
}
