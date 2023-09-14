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




function REPREPRO-Is-Available {
	$__process = OS-Is-Command-Available "reprepro"
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function REPREPRO-Publish {
	param (
		[string]$__target,
		[string]$__directory,
		[string]$__datastore,
		[string]$__codename
	)

	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__datastore) -or
		[string]::IsNullOrEmpty($__codename) -or
		(Test-Path "${__target}" -PathType Container) -or
		(-not (Test-Path "${__directory}" -PathType Container)) -or
		(-not (Test-Path "${__datastore}" -PathType Container))) {
		return 1
	}

	# execute
	$null = FS-Remake-Directory "${__datastore}\db"
	$null = FS-Remake-Directory "${__directory}"
	$__arguments = "--basedir `"${__datastore}`" " `
			+ "--outdir `"${__directory}`" " `
			+ "includedeb `"${__codename}`" " `
			+ "`"${__target}`""
	$__process = OS-Exec "reprepro" "${__arguments}"

	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}
