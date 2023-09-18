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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\versioners\git.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\crypto\gpg.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\changelog.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\checksum\shasum.ps1"




function RELEASE-Run-Checksum-Seal {
	# execute
	$__sha256_file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\sha256.txt"
	$__sha256_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\sha256.txt"
	$__sha512_file = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TEMP}\sha512.txt"
	$__sha512_target = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\sha512.txt"


	$null = FS-Remove-Silently "${__sha256_file}"
	$null = FS-Remove-Silently "${__sha256_target}"
	$null = FS-Remove-Silently "${__sha512_file}"
	$null = FS-Remove-Silently "${__sha512_target}"


	# gpg sign all packages
	$__process = GPG-Is-Available "${env:PROJECT_GPG_ID}"
	if ($__process -eq 0) {
		foreach ($TARGET in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}")) {
			$TARGET = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${TARGET}"
			if ($TARGET.EndsWith(".asc") {
				continue # it's a gpg cert
			}

			OS-Print-Status info "gpg signing: ${TARGET}"
			FS-Remove-Silently "${TARGET}.asc"
			$__process = GPG-Detach-Sign-File "${TARGET}" "${env:PROJECT_GPG_ID}"
			if ($__process -ne 0) {
				OS-Print-Status error "sign failed."
				return 1
			}
		}

		OS-Print-Status info "exporting GPG public key..."
		$__keyfile = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}\${env:PROJECT_SKU}.gpg.asc"
		$__process = GPG-Export-Public-Key "${__keyfile}" "${env:PROJECT_GPG_ID}"
		if ($__process -ne 0) {
			OS-Print-Status error "export failed."
			return 1
		}

		$__process = FS-Copy-File `
			"${__keyfile}" `
			"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}\${env:PROJECT_SKU}.gpg.asc"
		if ($__process -ne 0) {
			OS-Print-Status error "export failed."
			return 1
		}
	}


	# shasum all files
	foreach ($TARGET in (Get-ChildItem -Path "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_PKG}")) {
		if (-not ([string]::IsNullOrEmpty(${env:PROJECT_RELEASE_SHA256}))) {
			OS-Print-Status info "sha256 checksuming ${TARGET}"
			$__value = SHASUM-Checksum-File $TARGET.FullName "256"
			if ([string]::IsNullOrEmpty(${__value})) {
				OS-Print-Status error "sha256 failed."
				return 1
			}

			FS-Append-File "${__sha256_file}" @"
${__value}  $TARGET
"@
	}

		if (-not ([string]::IsNullOrEmpty(${env:PROJECT_RELEASE_SHA512}))) {
			OS-Print-Status info "sha512 checksuming ${TARGET}"
			$__value = SHASUM-Checksum-File $TARGET.FullName "512"
			if ([string]::IsNullOrEmpty(${__value})) {
				OS-Print-Status error "sha512 failed."
				return 1
			}

			$__process = FS-Append-File "${__sha512_file}" @"
${__value}  $TARGET
"@
			if ($__process -ne 0) {
				OS-Print-Status error "sha512 failed."
				return 1
			}
		}
	}


	if (Test-Path -Path "${__sha256_file}") {
		OS-Print-Status info "exporting sha256.txt..."
		$__process = FS-Move "${__sha256_file}" "${__sha256_target}"
		if ($__process -ne 0) {
			OS-Print-Status error "export failed."
			return 1
		}
	}


	if (Test-Path -Path "${__sha512_file}") {
		OS-Print-Status info "exporting sha512.txt..."
		$__process = FS-Move "${__sha512_file}" "${__sha512_target}"
		if ($__process -ne 0) {
			OS-Print-Status error "export failed."
			return 1
		}
	}


	# report status
	return 0
}




function RELEASE-Initiate {
	# safety check control surfaces
	OS-Print-Status info "Checking shasum availability..."
	$__process = SHASUM-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "Check failed."
		return 1
	}

	# execute
	if (-not ([string]::IsNullOrEmpty(${env:PROJECT_PYTHON}))) {
		$__recipe = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PYTHON}\${env:PROJECT_PATH_CI}"
		$__recipe = "${__recipe}\release_windows-any.ps1"
		OS-Print-Status info "Python technology detected. Parsing job recipe: ${__recipe}"

		$__process = FS-Is-File "${__recipe}"
		if ($__process -ne 0) {
			OS-Print-Status error "Parse failed - missing file."
			return 1
		}

		$__process = . "${__recipe}"
		if ($__process -ne 0) {
			return 1
		}
	}

	# report status
	return 0
}




function RELEASE-Run-Changelog-Conclude {
	# execute
	OS-Print-Status info "Sealing changelog latest entries..."
	$__process = CHANGELOG-Seal `
		"${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RESOURCES}\changelog" `
		"${env:PROJECT_VERSION}"
	if ($__process -ne 0) {
		return 1
	}

	# report status
	return 0
}




function RELEASE-Run-Release-Repo-Conclude {
	# validate input
	$__process = GIT-Is-Available
	if ($__process -ne 0) {
		OS-Print-Status error "Missing required git dependency."
		return 1
	}

	OS-Print-Status info "Sourcing commit id for tagging..."
	$__tag = GIT-Get-Latest-Commit-ID
	if ([string]::IsNullOrEmpty(${__tag})) {
		OS-Print-Status error "Source failed."
		return 1
	}

	# execute
	$__current_path = Get-Location
	$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"

	OS-Print-Status info "Committing release repo..."
	$__process = Git-Autonomous-Force-Commit `
		"${__tag}" `
		"${env:PROJECT_STATIC_REPO_KEY}" `
		"${env:PROJECT_STATIC_REPO_BRANCH}"
	if ($__process -ne 0) {
		$null = Set-Location "${__curent_path}"
		$null = Remove-Variable __current_path
		OS-Print-Status error "Commit failed."
		return 1
	}

	$null = Set-Location "${__curent_path}"
	$null = Remove-Variable __current_path

	# return status
	return 0
}




function RELEASE-Run-Release-Repo-Setup {
	# execute
	$__current_path = Get-Location
	$null = Set-Location "${env:PROJECT_PATH_ROOT}"


	OS-Print-Status info "Setup artifact release repo..."
	$__process = GIT-clone "${env:PROJECT_STATIC_REPO}" "${env:PROJECT_PATH_RELEASE}"
	if ($__process -eq 2) {
		OS-Print-Status info "Existing directory detected. Skipping..."
	} elseif ($__process -ne 0) {
		OS-Print-Status error "Setup failed."
		return 1
	}


	OS-Print-Status info "Hard resetting git to first commit..."
	$null = Set-Location "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_RELEASE}"
	$__process = GIT-Hard-Reset-To-Init
	if ($__process -ne 0) {
		$__current_path = Get-Location
		$null = Set-Location "${__current_path}"
		$null = Remove-Variable __current_path
		OS-Print-Status error "Reset failed."
		return 1
	}

	$__current_path = Get-Location
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable __current_path

	# report status
	return 0
}
