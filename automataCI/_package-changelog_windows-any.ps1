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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\changelog.ps1"




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return
}




function PACKAGE-Run-Changelog {
	param (
		[string]$__changelog_md,
		[string]$__changelog_deb
	)

	OS-Print-Status info "checking changelog functions availability..."
	$__process = CHANGELOG-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "checking failed."
		return 1
	}

	# validate input
	OS-Print-Status info "validating ${env:PROJECT_VERSION} data changelog entry..."
	$__process = CHANGELOG-Compatible-Data-Version `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
		"${env:PROJECT_VERSION}"
	if ($__process -ne 0) {
		OS-Print-Status error "validation failed - existing entry."
		return 1
	}

	OS-Print-Status info "validating ${env:PROJECT_VERSION} deb changelog entry..."
	$__process = CHANGELOG-Compatible-DEB-Version `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
		"${env:PROJECT_VERSION}"
	if ($__process -ne 0) {
		OS-Print-Status error "validation failed - existing entry."
		return 1
	}

	# assemble changelog
	OS-Print-Status info "assembling Markdown changelog..."
	$__process = CHANGELOG-Assemble-MD `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
		"${__changelog_md}" `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_CHANGELOG_TITLE}"
	if ($__process -ne 0) {
		OS-Print-Status error "assembly failed."
		return 1
	}

	OS-Print-Status info "assembling deb changelog..."
	$null = FS-Make-Housing-Directory "${__changelog_deb}"
	$__process = CHANGELOG-Assemble-DEB `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
		"${__changelog_deb}" `
		"${env:PROJECT_VERSION}"
	if ($__process -ne 0) {
		OS-Print-Status error "assembly failed."
		return 1
	}

	# report status
	return 0
}
