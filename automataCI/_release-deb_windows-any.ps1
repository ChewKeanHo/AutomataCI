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
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\deb.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\reprepro.ps1"

. "${env:LIBS_AUTOMATACI}\services\i18n\status-file.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\status-run.ps1"




function RELEASE-Run-DEB {
	param(
		[string]$__target,
		[string]$__directory
	)


	# validate input
	$___process = DEB-Is-Valid "${__target}"
	if ($___process -ne 0) {
		return 0
	}

	$null = I18N-Status-Print-Check-Availability "REPREPRO"
	$___process = REPREPRO-Is-Available
	if ($___process -ne 0) {
		$null = I18N-Status-Print-Check-Availability-Failed "REPREPRO"
		return 0
	}


	# execute
	$__conf = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\deb"
	$__file = "${__conf}\conf\distributions"
	$___process = FS-Is-File "${__file}"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-File-Create "${__file}"
		$___process = REPREPRO-Create-Conf `
			"${__conf}" `
			"${env:PROJECT_REPREPRO_CODENAME}" `
			"${env:PROJECT_DEBIAN_DISTRIBUTION}" `
			"${env:PROJECT_REPREPRO_COMPONENT}" `
			"${env:PROJECT_REPREPRO_ARCH}" `
			"${env:PROJECT_GPG_ID}"
		if ($___process -ne 0) {
			$null = I18N-Status-Print-File-Create-Failed
			return 1
		}
	}

	$__dest = "${__directory}/deb"
	$null = I18N-Status-Print-File-Create "${__dest}"
	$___process = FS-Make-Directory "${__dest}"
	if ($___process -ne 0) {
		$null = I18N-Status-Print-File-Create-Failed
		return 1
	}

	$null = I18N-Status-Print-Run-Publish "REPREPRO"
	if ([string]::IsNullOrEmpty(${env:PROJECT_SIMULATE_RELEASE_REPO})) {
		$null = I18N-Status-Print-Run-Publish-Simulated "REPREPRO"
	} else {
		$___process = REPREPRO-Publish `
			"${__target}" `
			"${__dest}" `
			"${__conf}" `
			"${__conf}\db" `
			"${env:PROJECT_REPREPRO_CODENAME}"
		if ($___process -ne 0) {
			$null = I18N-Status-Print-Run-Publish-Failed
			return 1
		}
	}


	# report status
	return 0
}
