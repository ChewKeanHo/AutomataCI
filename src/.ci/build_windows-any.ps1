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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\changelog.ps1"




# safety checking control surfaces
OS-Print-Status info "checking changelog availability..."
$__process = CHANGELOG-Is-Available
if ($__process -ne 0) {
	OS-Print-Status error "changelog builder is unavailable."
	return 1
}




# execute
$__file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog"
OS-Print-Status info "building ${env:PROJECT_VERSION} data changelog entry..."
$__process = CHANGELOG-Build-Data-Entry $__file
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}


OS-Print-Status info "building ${env:PROJECT_VERSION} deb changelog entry..."
$__process = CHANGELOG-Build-DEB-Entry `
	"${__file}" `
	"$env:PROJECT_VERSION" `
	"$env:PROJECT_SKU" `
	"$env:PROJECT_DEBIAN_DISTRIBUTION" `
	"$env:PROJECT_DEBIAN_URGENCY" `
	"$env:PROJECT_CONTACT_NAME" `
	"$env:PROJECT_CONTACT_EMAIL" `
	(Get-Date -Format 'R')
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# report status
return 0
