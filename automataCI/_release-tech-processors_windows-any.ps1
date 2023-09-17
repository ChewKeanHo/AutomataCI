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




function RELEASE-Run-Post-Processors {
	$__process = OS-Is-Command-Available "RELEASE-Run-Python-Post-Processor"
	if ($__process -eq 0) {
		OS-Print-Status info "running python post-processing function..."
		$__process = RELEASE-Run-Python-Post-Processor `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
		switch ($__process) {
		10 {
			# accepted
		} 0 {
			# accepted
		} Default {
			OS-Print-Status error "post-processor failed."
			return 1
		}}
	}

	# report status
	return 0
}




function RELEASE-Run-Pre-Processors {
	$__process = OS-Is-Command-Available "RELEASE-Run-Python-Pre-Processor"
	if ($__process -eq 0) {
		OS-Print-Status info "running python pre-processing function..."

		$__process = RELEASE-Run-Python-Pre-Processor `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
		switch ($__process) {
		10 {
			OS-Print-Status warning "release is not required. Skipping process."
			return 0
		} 0 {
			# accepted
		} Default {
			OS-Print-Status error "pre-processor failed."
			return 1
		}}
	}

	# report status
	return 0
}
