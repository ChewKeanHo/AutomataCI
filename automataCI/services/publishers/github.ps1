#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function GITHUB-Setup-Actions {
	# validate input
	if (($(STRINGS-Is-Empty "${env:PROJECT_ROBOT_RUN}") -eq 0) -and
		($(STRINGS-Is-Empty "${env:PROJECT_ROBOT_GITHUB_TOKEN}") -eq 0)) {
		return 0 # not a Github Actions run
	}


	# execute
	switch ("$(OS-Get)") {
	"darwin" {
		# OS Image = darwin-latest
	} "windows" {
		# OS Image = windows-latest
	} default {
		# OS Image = ubuntu-latest
		$___process = OS-Exec "sudo" "add-apt-repository universe"
		if ($___process -ne 0) {
			return 1
		}

		$___process = OS-Exec "sudo" "apt-get update"
		if ($___process -ne 0) {
			return 1
		}

		$___process = OS-Exec "sudo" "apt-get install -y libfuse2"
		if ($___process -ne 0) {
			return 1
		}
	}}


	# report status
	return 0
}
