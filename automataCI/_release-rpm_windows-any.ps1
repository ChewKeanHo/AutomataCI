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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\rpm.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\publishers\createrepo.ps1"




function RELEASE-Run-RPM {
	param(
		[string]$__target,
		[string]$__directory,
		[string]$__datastore
	)

	# validate input
	$__process = DEB-Is-Valid "${__target}"
	if ($__process -ne 0) {
		return 0
	}

	OS-Print-Status info "checking required createrepo availability..."
	$__process = CREATEREPO-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status warning "Createrepo is unavailable. Skipping..."
		return 0
	}

	# execute
	$__dest = "${__directory}/rpm"
	OS-Print-Status info "creating destination path..."
	$__process = FS-Make-Directory "${__dest}"
	if ($__process -ne 0) {
		OS-Print-Status error "create failed."
		return 1
	}

	OS-Print-Status info "publishing with createrepo..."
	$__process = CREATEREPO-Publish "${__target}" "${__dest}"
	if ($__process -ne 0) {
		OS-Print-Status error "publish failed."
		return 1
	}

	# report status
	return 0
}
