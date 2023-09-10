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




function DOCKER-Clean-Dangling-Images {
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
	$__id = STRINGS-To-Lowercase "${__repo}\${__sku}_${__os}-${__arch}:${__version}"

	$__process = FS-Is-File "${__dockerfile}"
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$__arguments = "buildx build " `
			+ "--platform `"${__os}/${__arch}`" " `
			+ "--file `"${__dockerfile}`" " `
			+ "--tag `"${__tag}`" " `
			+ "."
	$__process = OS-Exec "docker" $__arguments
	if ($__process -ne 0) {
		return 1
	}

	$__process = DOCKER-Save-Image "${__id}" "${__destination}"

	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function DOCKER-Is-Available {
	# execute
	$__process = OS-Is-Command-Available "docker"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "docker" "ps"
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function DOCKER-Save-Image {
	param(
		[string]$__id,
		[string]$__destination
	)

	# validate input
	if ([string]::IsNullOrEmpty($__id) -or
		[string]::IsNullOrEmpty($__destination)) {
		return 1
	}

	$__process = DOCKER-Is-Available
	if ($__process -ne 0) {
		return 1
	}

	# execute
	$__process = OS-Exec "docker" "`"${__id}`" > ${__destination}"

	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}
