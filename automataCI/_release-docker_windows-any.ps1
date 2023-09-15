# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at:
#               http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\docker.ps1"




function RELEASE-Run-DOCKER {
	param(
		[string]$_target,
		[string]$_directory,
		[string]$_datastore
	)

	# validate input
	$__process = DOCKER-Is-Valid "${_target}"
	if ($__process -ne 0) {
		return 0
	}

	OS-Print-Status info "checking required docker availability..."
	$__process = DOCKER-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status warning "Docker is unavailable. Skipping..."
		return 0
	}

	# execute
	OS-Print-Status info "releasing docker as the latest version..."
	$__process = DOCKER-Release `
		"${_target}" `
		"${_directory}" `
		"${_datastore}" `
		"${env:PROJECT_VERSION}"
	if ($__process -ne 0) {
		OS-Print-Status error "release failed."
		return 1
	}

	OS-Print-Status info "remove package artifact..."
	$null = FS-Remove-Silently "${_target}"

	# report status
	return 0
}
