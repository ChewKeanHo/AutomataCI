# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"




function NODE-Setup {
	# validate input
	$null = OS-Sync

	$___process =  OS-Is-Command-Available "npm"
	if ($___process -eq 0) {
		return 0
	}

	$___process =  OS-Is-Command-Available "choco"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "choco" "install node -y"
	if ($___process -ne 0) {
		return 1
	}

	$null = OS-Sync


	# report status
	return 0
}
