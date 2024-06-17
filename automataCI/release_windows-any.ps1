# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"

. "${env:LIBS_AUTOMATACI}\_release-cargo_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-changelog_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-checksum_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-citation_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-deb_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-flatpak_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-docker_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-homebrew_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-lib_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-npm_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-project_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-pypi_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-research_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-rpm_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_release-docsrepo_windows-any.ps1"




# execute
$___process = RELEASE-Initiate-CHECKSUM
if ($___process -ne 0) {
	return 1
}


$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}\${env:PROJECT_PATH_CI}"
$__recipe = "${__recipe}\release_windows-any.ps1"
$___process = FS-Is-File "${__recipe}"
if ($___process -eq 0) {
	$null = I18N-Detected "${__recipe}"
	$null = I18N-Parse "${__recipe}"
	$___process = . "${__recipe}"
	if ($___process -ne 0) {
		$null = I18N-Parse-Failed
		return 1
	}
}




# determine pathing variables
$PACKAGE_DIRECTORY = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"




# initialize workspace and release job functions
$___process = OS-Is-Command-Available "RELEASE-Run-Pre-Processor"
if ($___process -eq 0) {
	$___process = RELEASE-Run-Pre-Processor
	if ($___process -ne 0) {
		return 1
	}
}


$___process = RELEASE-Setup-PROJECT # !! IMPORTANT !! - always the first
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Setup-DEB "${DEB_REPO}"
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Setup-FLATPAK "$FLATPAK_REPO"
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Setup-HOMEBREW "${HOMEBREW_REPO}"
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Setup-RPM "${RPM_REPO}"
if ($___process -ne 0) {
	return 1
}




# scan through each product and run the release processing respectively
foreach ($TARGET in (Get-ChildItem -Path "${PACKAGE_DIRECTORY}")) { $TARGET = $TARGET.FullName
	if ($TARGET -like "*.asc") {
		continue # it's a gpg cert
	}

	if ($TARGET -like "*.gpg") {
		continue # it's a gpg keyfile or cert
	}

	$null = I18N-Processing "${TARGET}"

	$___process = RELEASE-Run-CARGO "$TARGET"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-CITATION-CFF "$TARGET"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-DEB "$TARGET" "$DEB_REPO" "$DEB_REPO_DATA"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-DOCKER "$TARGET"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-HOMEBREW "$TARGET" "$HOMEBREW_REPO"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-LIBS "$TARGET"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-NPM "$TARGET"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-PYPI "$TARGET"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-RESEARCH "$TARGET"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RELEASE-Run-RPM "$TARGET" "$RPM_REPO"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "RELEASE-Run-Package-Processor"
	if ($___process -eq 0) {
		$___process = RELEASE-Run-Package-Processor "$TARGET"
		if ($___process -ne 0) {
			return 1
		}
	}
}




# run one-time directory-wide release processing functions
$___process = RELEASE-Update-DEB "$DEB_REPO" "$DEB_REPO_DATA"
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Update-RPM "$RPM_REPO"
if ($___process -ne 0) {
	return 1
}


$___process = OS-Is-Command-Available "RELEASE-Run-Post-Processor"
if ($___process -eq 0) {
	$___process = RELEASE-Run-Post-Processor
	if ($___process -ne 0) {
		return 1
	}
}




# conclude the release
$___process = RELEASE-Conclude-CHECKSUM "$PACKAGE_DIRECTORY" ## !! IMPORTANT !! - always the first
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Conclude-DEB "$DEB_REPO"
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Conclude-FLATPAK "$FLATPAK_REPO"
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Conclude-HOMEBREW "$HOMEBREW_REPO"
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Conclude-RPM "$RPM_REPO"
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Conclude-DOCS
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Conclude-CHANGELOG
if ($___process -ne 0) {
	return 1
}


$___process = RELEASE-Conclude-PROJECT # !! IMPORTANT !! - must always be the last
if ($___process -ne 0) {
	return 1
}




# report status
$null = I18N-Run-Successful
return 0
