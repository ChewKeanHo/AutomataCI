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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\deb.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\reprepro.ps1"




function RELEASE-Run-DEB {
	param(
		[string]$__target,
		[string]$__directory
	)


	# validate input
	$__process = DEB-Is-Valid "${__target}"
	if ($__process -ne 0) {
		return 0
	}

	OS-Print-Status info "checking required reprepro availability..."
	$__process = REPREPRO-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status warning "Reprepro is unavailable. Skipping..."
		return 0
	}


	# execute
	$__conf = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb"
	$__process = FS-Is-File "${__conf}\conf\distributions"
	if ($__process -ne 0) {
		OS-Print-Status info "create reprepro configuration file..."
		$__process = REPREPRO-Create-Conf `
			"${__conf}" `
			"${env:PROJECT_REPREPRO_CODENAME}" `
			"${env:PROJECT_DEBIAN_DISTRIBUTION}" `
			"${env:PROJECT_REPREPRO_COMPONENT}" `
			"${env:PROJECT_REPREPRO_ARCH}" `
			"${env:PROJECT_GPG_ID}"
		if ($__process -ne 0) {
			OS-Print-Status error "create failed."
			return 1
		}
	}

	$__dest = "${__directory}/deb"
	OS-Print-Status info "creating destination path: ${__dest}"
	$__process = FS-Make-Directory "${__dest}"
	if ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	OS-Print-Status info "publishing with reprepro..."
	if ([string]::IsNullOrEmpty(${env:PROJECT_SIMULATE_RELEASE_REPO})) {
		OS-Print-Status warning "Simulating reprepro release..."
	} else {
		$__process = REPREPRO-Publish `
			"${__target}" `
			"${__dest}" `
			"${__conf}" `
			"${__conf}\db" `
			"${env:PROJECT_REPREPRO_CODENAME}"
		if ($__process -ne 0) {
			OS-Print-Status error "publish failed."
			return 1
		}
	}


	# report status
	return 0
}
