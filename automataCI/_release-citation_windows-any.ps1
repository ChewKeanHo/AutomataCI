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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\time.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\citation.ps1"




function RELEASE-Run-Citation {
	# execute
	OS-Print-Status info "generating citation file..."
	$__process = CITATION-Build `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\CITATION.cff" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs\ABSTRACTS.txt" `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\docs\CITATIONS.yml" `
		"${env:PROJECT_CITATION}" `
		"${env:PROJECT_CITATION_TYPE}" `
		"$(TIME-Format-ISO8601-Date "$(TIME-Now)")" `
		"${env:PROJECT_NAME}" `
		"${env:PROJECT_VERSION}" `
		"${env:PROJECT_LICENSE}" `
		"${env:PROJECT_SOURCE_URL}" `
		"${env:PROJECT_SOURCE_URL}" `
		"${env:PROJECT_STATIC_URL}" `
		"${env:PROJECT_CONTACT_NAME}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_CONTACT_EMAIL}"
	if ($__process -ne 0) {
		OS-Print-Status error "generate failed."
		return 1
	}


	if (Test-Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\CITATION.cff") {
		OS-Print-Status info "exporting CITATION.cff..."
		$__process = FS-Copy-File `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\CITATION.cff" `
			"${env:PROJECT_PATH_ROOT}\CITATION.cff"
		if ($__process -ne 0) {
			OS-Print-Status error "export failed."
			return 1
		}
	}


	# report status
	return 0
}
