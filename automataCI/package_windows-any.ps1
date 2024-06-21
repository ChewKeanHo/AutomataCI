# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
	Write-Error "[ ERROR ] - Please run me from automataCI\ci.sh.ps1 instead!`n"
	return 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\sync.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\compilers\flatpak.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\homebrew.ps1"
. "${env:LIBS_AUTOMATACI}\services\versioners\git.ps1"

. "${env:LIBS_AUTOMATACI}\_package-changelog_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_package-citation_windows-any.ps1"
. "${env:LIBS_AUTOMATACI}\_package-msi_windows-any.ps1"




# 1-time setup job required materials
$DEST = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
$null = I18N-Remake "${DEST}"
$___process = FS-Remake-Directory "${DEST}"
if ($___process -ne 0) {
	$null = I18N-Remake-Failed
	return 1
}


if ($(STRINGS-Is-Empty "${env:PROJECT_HOMEBREW_URL}") -ne 0) {
	$HOMEBREW_WORKSPACE = "packagers-homebrew-${env:PROJECT_SKU}"
	$null = I18N-Setup "${HOMEBREW_WORKSPACE}"
	$HOMEBREW_WORKSPACE = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${HOMEBREW_WORKSPACE}"
	$___process = FS-Remake-Directory "${HOMEBREW_WORKSPACE}"
	if ($___process -ne 0) {
		$null = I18N-Setup-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_MSI_INSTALL_DIRECTORY}") -ne 0) {
	$MSI_WORKSPACE = "packagers-msi-${env:PROJECT_SKU}"
	$null = I18N-Setup "${MSI_WORKSPACE}"
	$MSI_WORKSPACE = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${MSI_WORKSPACE}"
	$___process = FS-Remake-Directory "${MSI_WORKSPACE}"
	if ($___process -ne 0) {
		$null = I18N-Setup-Failed
		return 1
	}


	if ($(STRINGS-Is-Empty "${env:PROJECT_MSI_REGISTRY_KEY}") -eq 0) {
		${env:PROJECT_MSI_REGISTRY_KEY} = @"
Software\${env:PROJECT_SCOPE}\InstalledProducts\${env:PROJECT_SKU_TITLECASE}
"@
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_FLATPAK_URL}") -ne 0) {
	$FLATPAK_REPO = "flatpak-repo"
	$null = I18N-Setup "${FLATPAK_REPO}"
	$FLATPAK_REPO = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\${FLATPAK_REPO}"
	$null = FS-Remove-Silently "$FLATPAK_REPO"

	if (($(STRINGS-Is-Empty "${env:PROJECT_FLATPAK_REPO}") -ne 0) -and
		($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_REPO}") -ne 0)) {
		# version controlled repository supplied; AND
		# single unified repository is not enabled
		$null = FS-Make-Housing-Directory "$FLATPAK_REPO"
		$___process = GIT-Clone-Repo `
			"${env:PROJECT_PATH_ROOT}" `
			"${env:PROJECT_PATH_TEMP}" `
			"$(Get-Location)" `
			"${env:PROJECT_FLATPAK_REPO}" `
			"${env:PROJECT_SIMULATE_RUN}" `
			"$(FS-Get-File "${env:FLATPAK_REPO}")" `
			"${env:PROJECT_FLATPAK_REPO_BRANCH}"
		if ($___process -ne 0) {
			$null = I18N-Setup-Failed
			return 1
		}

		if ($(STRINGS-Is-Empty "${env:PROJECT_FLATPAK_PATH}") -ne 0) {
			$FLATPAK_REPO = "${FLATPAK_REPO}/${env:PROJECT_FLATPAK_PATH}"
		}
	}

	$___process = FS-Make-Directory "$FLATPAK_REPO"
	if ($___process -ne 0) {
		$null = I18N-Setup-Failed
		return 1
	}
}


$FILE_CHANGELOG_MD = "${env:PROJECT_SKU}-CHANGELOG_${env:PROJECT_VERSION}.md"
$FILE_CHANGELOG_MD = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${FILE_CHANGELOG_MD}"
$FILE_CHANGELOG_DEB = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\packagers-changelog\deb.gz"
$___process = Package-Run-CHANGELOG "$FILE_CHANGELOG_MD" "$FILE_CHANGELOG_DEB"
if ($___process -ne 0) {
	return 1
}


$FILE_CITATION_CFF = "${env:PROJECT_SKU}-CITATION_${env:PROJECT_VERSION}.cff"
$FILE_CITATION_CFF = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${FILE_CITATION_CFF}"
$___process = Package-Run-CITATION "$FILE_CITATION_CFF"
if ($___process -ne 0) {
	return 1
}


$null = I18N-Newline




# prepare for parallel package
$__log_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_LOG}\packagers"
$null = I18N-Remake "${__log_directory}"
$null = FS-Remake-Directory "${__log_directory}"
$___process = FS-Is-Directory "${__log_directory}"
if ($___process -ne 0) {
	$null = I18N-Remake-Failed
	return 1
}


$__control_directory = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\packagers-parallel"
$null = I18N-Remake "${__control_directory}"
$null = FS-Remake-Directory "${__control_directory}"
$___process = FS-Is-Directory "${__control_directory}"
if ($___process -ne 0) {
	$null = I18N-Remake-Failed
	return 1
}


$__parallel_control = "${__control_directory}\control-parallel.txt"
$null = FS-Remove-Silently "${__parallel_control}"


$__serial_control = "${__control_directory}\control-serial.txt"
$null = FS-Remove-Silently "${__serial_control}"


function SUBROUTINE-Package {
	param(
		[string]$__line
	)


	# initialize libraries from scratch
	$null = . "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"

	$null = . "${env:LIBS_AUTOMATACI}\_package-archive_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-cargo_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-changelog_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-chocolatey_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-deb_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-docker_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-flatpak_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-homebrew_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-ipk_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-lib_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-msi_windows-any.ps1"

	$null = . "${env:LIBS_AUTOMATACI}\_package-pypi_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-rpm_windows-any.ps1"
	$null = . "${env:LIBS_AUTOMATACI}\_package-sourcing_windows-any.ps1"


	# parse input
	$__command = $__line.Split("|")[-1]
	$__log = $__line.Split("|")[-2]
	$__arguments = $__line.Split("|")
	$__arguments = $__arguments[0..$($__arguments.Length - 3)]
	$__arguments = $__arguments -Join "|"

	$__subject = Split-Path -Leaf -Path "${__log}"
	$__subject = FS-Extension-Remove "${__subject}" "*"


	# execute
	$null = I18N-Package "${__subject}"
	$null = FS-Remove-Silently "${__log}"

	try {
		${function:SUBROUTINE-Exec} = Get-Command `
			"${__command}" `
			-ErrorAction SilentlyContinue
		$($___process = SUBROUTINE-Exec "${__arguments}") *> "${__log}"
	} catch {
		$___process = 1
	}
	if ($___process -ne 0) {
		$null = I18N-Package-Failed
		return 1
	}


	# report status
	return 0
}




# begin registering packagers
if ($(FS-Is-Directory "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}") -eq 0) {
foreach ($i in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}")) {
	$i = $i.FullName

	$___process = FS-Is-File "$i"
	if ($___process -ne 0) {
		continue
	}


	# parse build candidate
	$null = I18N-Detected "${i}"
	$TARGET_FILENAME = Split-Path -Leaf $i
	$TARGET_FILENAME = $TARGET_FILENAME -replace "\..*$"
	$TARGET_OS = $TARGET_FILENAME -replace ".*_"
	$TARGET_FILENAME = $TARGET_FILENAME -replace "_.*"
	$TARGET_ARCH = $TARGET_OS -replace ".*-"
	$TARGET_ARCH = $TARGET_ARCH -replace "\..*$"
	$TARGET_OS = $TARGET_OS -replace "-.*"
	$TARGET_OS = $TARGET_OS -replace "\..*$"

	if (($(STRINGS-Is-Empty "${TARGET_OS}") -eq 0) -or
		($(STRINGS-Is-Empty "${TARGET_ARCH}") -eq 0) -or
		($(STRINGS-Is-Empty "${TARGET_FILENAME}") -eq 0)) {
		$null = I18N-File-Has-Bad-Stat-Skipped
		continue
	}

	$___process = STRINGS-Has-Prefix "${env:PROJECT_SKU}" "${TARGET_FILENAME}"
	if ($___process -ne 0) {
		$___process = STRINGS-Has-Prefix "lib${env:PROJECT_SKU}" "${TARGET_FILENAME}"
		if ($___process -ne 0) {
			$null = I18N-Is-Incompatible-Skipped "${TARGET_FILENAME}"
			continue
		}
	}

	$__common = "${DEST}|${i}|${TARGET_FILENAME}|${TARGET_OS}|${TARGET_ARCH}"


	# begin registrations
	$null = I18N-Sync-Register "$i"

	if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_ARCHIVE}") -ne 0) {
		$__log = "archive_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
		$__log = "${__log_directory}\${__log}"
		$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-ARCHIVE

"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_RUST}") -ne 0) {
		$__log = "cargo_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
		$__log = "${__log_directory}\${__log}"
		$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-CARGO

"@
		if ($___process -ne 0) {
			return 1
		}
	}

	# NOTE: chocolatey only serve windows
	if ($(STRINGS-Is-Empty "${env:PROJECT_CHOCOLATEY_URL}") -ne 0) {
		switch ("${TARGET_OS}") {
		{ $_ -in "any", "windows" } {
			$__log = "chocolatey_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
			$__log = "${__log_directory}\${__log}"
			$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-CHOCOLATEY

"@
			if ($___process -ne 0) {
				return 1
			}
		} default {
		}}
	}

	# NOTE: deb does not work in windows or mac
	if ($(STRINGS-Is-Empty "${env:PROJECT_DEB_URL}") -ne 0) {
		switch ("${TARGET_OS}") {
		{ $_ -in "windows", "darwin" } {
			$__log = "deb_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
			$__log = "${__log_directory}\${__log}"
			$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${FILE_CHANGELOG_DEB}|${__log}|PACKAGE-Run-DEB

"@
			if ($___process -ne 0) {
				return 1
			}
		} default {
		}}
	}

	# NOTE: container only server windows and linux
	if ($(STRINGS-Is-Empty "${env:PROJECT_CONTAINER_REGISTRY}") -ne 0) {
		switch ("${TARGET_OS}") {
		{ $_ -in "any", "linux", "windows" } {
			$__log = "docker_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
			$__log = "${__log_directory}\${__log}"
			$___process = FS-Append-File "${__serial_control}" @"
${__common}|${__log}|PACKAGE-Run-DOCKER

"@
			if ($___process -ne 0) {
				return 1
			}
		} default {
		}}
	}

	# NOTE: flatpak only serve linux
	$___process = FLATPAK-Is-Available
	if (($___process -eq 0) -and
		($(STRINGS-Is-Empty "${env:PROJECT_FLATPAK_URL}") -ne 0)) {
		switch ("${TARGET_OS}") {
		{ $_ -in "any", "linux" } {
			$__log = "flatpak_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
			$__log = "${__log_directory}\${__log}"
			$___process = FS-Append-File "${__serial_control}" @"
${__common}|${FLATPAK_REPO}|${__log}|PACKAGE-Run-FLATPAK

"@
			if ($___process -ne 0) {
				return 1
			}
		} default {
		}}
	}

	# NOTE: homebrew only serve linux and mac
	if ($(STRINGS-Is-Empty "${env:PROJECT_HOMEBREW_URL}") -ne 0) {
		switch ("${TARGET_OS}") {
		{ $_ -in "any", "darwin", "linux" } {
			$__log = "homebrew_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
			$__log = "${__log_directory}\${__log}"
			$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${HOMEBREW_WORKSPACE}|${__log}|PACKAGE-Run-HOMEBREW

"@
			if ($___process -ne 0) {
				return 1
			}
		} default {
		}}
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_IPK}") -ne 0) {
		$__log = "ipk_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
		$__log = "${__log_directory}\${__log}"
		$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-IPK

"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if (($(FS-Is-Target-A-Library "${i}") -eq 0) -and
		($(STRINGS-Is-Empty "${env:PROJECT_RELEASE_ARCHIVE}") -ne 0)) {
		$__log = "lib_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
		$__log = "${__log_directory}\${__log}"
		$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-LIB

"@
		if ($___process -ne 0) {
			return 1
		}
	}

	# NOTE: MSI only works in windows
	if ($(STRINGS-Is-Empty "${env:PROJECT_MSI_INSTALL_DIRECTORY}") -ne 0) {
		switch ("${TARGET_OS}") {
		{ $_ -in "any", "windows" } {
			$__log = "msi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
			$__log = "${__log_directory}\${__log}"
			$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${MSI_WORKSPACE}|${__log}|PACKAGE-Run-MSI

"@
			if ($___process -ne 0) {
				return 1
			}
		} default {
		}}
	}

	if ($(FS-Is-Target-A-PDF "${i}") -eq 0) {
		$__log = "PDF_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
		$__log = "${__log_directory}\${__log}"
		$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-PDF

"@
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PYTHON}") -ne 0) {
		$__log = "pypi_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
		$__log = "${__log_directory}\${__log}"
		$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-PYPI

"@
		if ($___process -ne 0) {
			return 1
		}
	}

	# NOTE: RPM only serve linux
	if ($(STRINGS-Is-Empty "${env:PROJECT_RPM_URL}") -ne 0) {
		switch ("${TARGET_OS}") {
		{ $_ -in "any", "linux" } {
			$__log = "rpm_${TARGET_FILENAME}_${TARGET_OS}-${TARGET_ARCH}.log"
			$__log = "${__log_directory}\${__log}"
			$___process = FS-Append-File "${__parallel_control}" @"
${__common}|${__log}|PACKAGE-Run-RPM

"@
			if ($___process -ne 0) {
				return 1
			}
		} default {
		}}
	}
}
}


$null = I18N-Sync-Run
$___process = FS-Is-File "${__parallel_control}"
if ($___process -eq 0) {
	$___process = SYNC-Exec-Parallel `
		${function:SUBROUTINE-Package}.ToString() `
		"${__parallel_control}" `
		"${__control_directory}"
	if ($___process -ne 0) {
		$null = I18N-Sync-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_HOMEBREW_URL}") -ne 0) {
	$null = I18N-Newline
	$null = I18N-Newline

	$__dest = "${env:PROJECT_SKU}.rb"
	$null = I18N-Export "${__dest}"
	$__dest = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${__dest}"
	$___process = HOMEBREW-Seal "${__dest}" `
		"${env:PROJECT_SKU}-homebrew_${env:PROJECT_VERSION}_any-any.tar.xz" `
		"${HOMEBREW_WORKSPACE}" `
		"${env:PROJECT_SKU}" `
		"${env:PROJECT_PITCH}" `
		"${env:PROJECT_CONTACT_WEBSITE}" `
		"${env:PROJECT_LICENSE}" `
		"${env:PROJECT_HOMEBREW_URL}"
	if ($___process -ne 0) {
		$null = I18N-Export-Failed
		return 1
	}
}


if ($(STRINGS-Is-Empty "${env:PROJECT_MSI_INSTALL_DIRECTORY}") -ne 0) {
	$null = I18N-Newline
	$null = I18N-Newline


	# sort 'any' arch into others
	$___process = PACKAGE-Sort-MSI "${MSI_WORKSPACE}"
	if ($___process -ne 0) {
		return 1
	}

	# seal all MSI packages
	foreach ($_candidate in (Get-ChildItem -Path "${MSI_WORKSPACE}" -Directory)) {
		$_candidate = $_candidate.FullName

		$null = I18N-Newline

		$___process = PACKAGE-Seal-MSI `
				"${_candidate}" `
				"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}"
		if ($___process -ne 0) {
			return 1
		}
	}
}


$null = I18N-Sync-Run-Series
$___process = FS-Is-File "${__serial_control}"
if ($___process -eq 0) {
	$___process = SYNC-Exec-Serial `
		${function:SUBROUTINE-Package}.ToString() `
		"${__serial_control}"
	if ($___process -ne 0) {
		$null = I18N-Sync-Failed
		return 1
	}
}




# report status
$null = I18N-Run-Successful
return 0
