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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function APPLE-Install-DMG {
	param(
		[string]$___target
	)


	# validate input
	$___process = FS-Is-File "${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "hdiutil"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "grep"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "awk"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "cp"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___image = Mount-DiskImage -ImagePath "${___target}" -PassThru
	$___volumesLine = $___image | Select-String -Pattern "Volumes"
	$___volumePath = $___volumesLine -split '\s+' | Select-Object -Index 2
	$___volume = $___volumePath
	if ($(STRINGS-Is-Empty "${___volume}") -eq 0) {
		return 1
	}

	$null = Copy-Item \
		-Recurse \
		-Force \
		-Path "${___volume}\*.app" \
		-Destination "/Applications"
	if ($?) {
		$___process = 0
	} else {
		$___process = 1
	}

	$null = Dismount-DiskImage -ImagePath $___image.ImagePath
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
