# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\strings.ps1"




function RUST-Activate-Local-Environment {
	# validate input
	$__process = RUST-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__location = "$(RUST-Get-Activator-Path)"
	if (-not (Test-Path "${__location}")) {
		return 1
	}

	. $__location
	$__process = RUST-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function RUST-Cargo-Login {
	# validate input
	if ([string]::IsNullOrEmpty(${env:CARGO_REGISTRY}) -or
		[string]::IsNullOrEmpty(${env:CARGO_PASSWORD})) {
		return 1
	}


	# execute
	$__arguments = "login " `
		+ "--registry `"${env:CARGO_REGISTRY}`" " `
		+ "`"${env:CARGO_PASSWORD}`" "
	$__process = OS-Exec "cargo" "${__arguments}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Cargo-Logout {
	# execute
	$__process = OS-Exec "cargo" "logout"
	if ($__process -ne 0) {
		return 1
	}

	$null = FS-Remove-Silently "\.cargo\credentials.toml"


	# report status
	return 0
}




function RUST-Cargo-Release-Crate {
	param(
		[string]$__source_directory
	)


	# validate input
	if ([string]::IsNullOrEmpty($__source_directory) -or
		(-not (Test-Path -PathType Container -Path "${__source_directory}"))) {
		return 1
	}


	# execute
	$__current_path = Get-Location
	$null = Set-Location "${__source_directory}"
	$__process = OS-Exec "cargo" "publish"
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable __current_path

	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Crate-Is-Valid {
	param(
		[string]$__target
	)


	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		(-not (Test-Path -PathType Container -Path "${__target}"))) {
		return 1
	}


	# execute
	$__process = STRINGS-Has-Prefix "cargo" (Split-Path -Leaf -Path "${__target}")
	if ($__process -ne 0) {
		return 1
	}

	$__hasCARGO = "false"
	foreach ($__file in (Get-ChildItem -Path ${__target})) {
		if ($__file.Name -eq "Cargo.toml") {
			$__hasCARGO = "true"
		}
	}
	if ($__hasCARGO -eq "true") {
		return 0
	}


	# report status
	return 1
}




function RUST-Create-Archive {
	param(
		[string]$__source_directory,
		[string]$__target_directory
	)


	# validate input
	if ([string]::IsNullOrEmpty($__source_directory) -or
		[string]::IsNullOrEmpty($__target_directory) -or
		(-not (Test-Path -PathType Container -Path "${__source_directory}")) -or
		(-not (Test-Path -PathType Container -Path "${__target_directory}"))) {
		return 1
	}

	$__process = RUST-Is-Localized
	if ($__process -ne 0) {
		$__process = RUST-Activate-Local-Environment
		if ($__process -ne 0) {
			return 1
		}
	}


	# execute
	$null = FS-Remove-Silently "${__source_directory}\Cargo.lock"

	$__current_path = Get-Location
	$null = Set-Location "${__source_directory}"

	$__process = OS-Exec "cargo" "build"
	if ($__process -ne 0) {
		$null = Set-Location "${__current_path}"
		$null = Remove-Variable __current_path
		return 1
	}

	$__process = OS-Exec "cargo" "publish --dry-run"
	if ($__process -ne 0) {
		$null = Set-Location "${__current_path}"
		$null = Remove-Variable __current_path
		return 1
	}

	$null = Set-Location "${__current_path}"
	$null = Remove-Variable __current_path

	$null = FS-Remove-Silently "${__source_directory}\target"
	$null = FS-Remake-Directory "${__target_directory}"
	$__process = FS-Copy-All "${__source_directory}\" "${__target_directory}"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Create-Cargo-TOML {
	param(
		[string]$__filepath,
		[string]$__template,
		[string]$__sku,
		[string]$__version,
		[string]$__pitch,
		[string]$__edition,
		[string]$__license,
		[string]$__docs,
		[string]$__website,
		[string]$__repo,
		[string]$__readme,
		[string]$__contact_name,
		[string]$__contact_email
	)


	# validate input
	if ([string]::IsNullOrEmpty($__filepath) -or
		[string]::IsNullOrEmpty($__template) -or
		(-not (Test-Path "${__template}")) -or
		[string]::IsNullOrEmpty($__sku) -or
		[string]::IsNullOrEmpty($__version) -or
		[string]::IsNullOrEmpty($__pitch) -or
		[string]::IsNullOrEmpty($__edition) -or
		[string]::IsNullOrEmpty($__license) -or
		[string]::IsNullOrEmpty($__docs) -or
		[string]::IsNullOrEmpty($__website) -or
		[string]::IsNullOrEmpty($__repo) -or
		[string]::IsNullOrEmpty($__readme) -or
		[string]::IsNullOrEmpty($__contact_name) -or
		[string]::IsNullOrEmpty($__contact_email)) {
		return 1
	}


	# execute
	$null = FS-Remove-Silently "${__filepath}"
	$__process = FS-Write-File "${__filepath}" @"
[package]
name = '${__sku}'
version = '${__version}'
description = '${__pitch}'
edition = '${__edition}'
license = '${__license}'
documentation = '${__docs}'
homepage = '${__website}'
repository = '${__repo}'
readme = '${__readme}'
authors = [ '${__contact_name} <${__contact_email}>' ]




"@
	if ($__process -ne 0) {
		return 1
	}


	$__begin_append = 1
	foreach ($__line in (Get-Content "${__template}")) {
		if (($__begin_append -ne 0) -and
			($("${__line}" -replace '\[AUTOMATACI BEGIN\]') -ne "${__line}")) {
			$__begin_append = 0
			continue
		}

		if ($__begin_append -ne 0) {
			continue
		}

		$__process = FS-Append-File "${__filepath}" "${__line}"
		if ($__process -ne 0) {
			return 1
		}
	}


	# update Cargo.lock
	$__process = RUST-Is-Localized
	if ($__process -ne 0) {
		$__process = RUST-Activate-Local-Environment
		if ($__process -ne 0) {
			return 1
		}
	}

	$__current_path = Get-Location
	$null = Set-Location (Split-Path -Parent -Path "${__filepath}")
	$__process = OS-Exec "cargo" "update"
	if ($__process -ne 0) {
		$null = Set-Location "${__current_path}"
		$null = Remove-Variable __current_path
		return 1
	}

	$__process = OS-Exec "cargo" "clean"
	$null = Set-Location "${__current_path}"
	$null = Remove-Variable __current_path
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Get-Activator-Path {
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}" `
		+ "\${env:PROJECT_PATH_RUST_ENGINE}\Activate.ps1"
}




function RUST-Get-Build-Target {
	param(
		[string]$__os,
		[string]$__arch
	)


	# execute
	switch ("${__os}-${__arch}") {
	aix-ppc64 {
		return "powerpc64-ibm-aix"
	} android-amd64 {
		return "x86_64-linux-android"
	} android-arm64 {
		return "aarch64-linux-android"
	} darwin-amd64 {
		return "x86_64-apple-darwin"
	} darwin-arm64 {
		return "aarch64-apple-darwin"
	} dragonfly-amd64 {
		return "x86_64-unknown-dragonfly"
	} freebsd-amd64 {
		return "x86_64-unknown-freebsd"
	} fuchsia-amd64 {
		return "x86_64-unknown-fuchsia"
	} fuchsia-arm64 {
		return "aarch64-unknown-fuchsia"
	} haiku-amd64 {
		return "x86_64-unknown-haiku"
	} illumos-amd64 {
		return "x86_64-unknown-illumos"
	} ios-amd64 {
		return "x86_64-apple-ios"
	} ios-arm64 {
		return "aarch64-apple-ios"
	} js-wasm {
		return "wasm32-unknown-emscripten"
	} { $_ -in "linux-armel", "linux-armle" } {
		return "arm-unknown-linux-musleabi"
	} linux-armhf {
		return "arm-unknown-linux-musleabihf"
	} linux-armv7 {
		return "armv7-unknown-linux-musleabihf"
	} linux-amd64 {
		return "x86_64-unknown-linux-musl"
	} linux-arm64 {
		return "aarch64-unknown-linux-musl"
	} linux-loongarch64 {
		return "loongarch64-unknown-linux-gnu"
	} linux-mips {
		return "mips-unknown-linux-musl"
	} { $_ -in "linux-mipsle", "linux-mipsel" } {
		return "mipsel-unknown-linux-musl"
	} linux-mips64 {
		return "mips64-unknown-linux-muslabi64"
	} { $_ -in "linux-mips64el", "linux-mips64le" } {
		return "mips64el-unknown-linux-muslabi64"
	} linux-ppc64 {
		return "powerpc64-unknown-linux-gnu"
	} linux-ppc64le {
		return "powerpc64le-unknown-linux-gnu"
	} linux-riscv64 {
		return "riscv64gc-unknown-linux-gnu"
	} linux-s390x {
		return "s390x-unknown-linux-gnu"
	} linux-sparc {
		return "sparc-unknown-linux-gnu"
	} netbsd-amd64 {
		return "x86_64-unknown-netbsd"
	} netbsd-arm64 {
		return "aarch64-unknown-netbsd"
	} netbsd-riscv64 {
		return "riscv64gc-unknown-netbsd"
	} netbsd-sparc {
		return "sparc64-unknown-netbsd"
	} openbsd-amd64 {
		return "x86_64-unknown-openbsd"
	} openbsd-arm64 {
		return "aarch64-unknown-openbsd"
	} openbsd-ppc64 {
		return "powerpc64-unknown-openbsd"
	} openbsd-riscv64 {
		return "riscv64gc-unknown-openbsd"
	} openbsd-sparc {
		return "sparc64-unknown-openbsd"
	} redox-amd64 {
		return "x86_64-unknown-redox"
	} solaris-amd64 {
		return "x86_64-pc-solaris"
	} wasip1-wasm {
		return "wasm32-wasi"
	} windows-amd64 {
		return "x86_64-pc-windows-msvc"
	} windows-arm64 {
		return "aarch64-pc-windows-msvc"
	} default {
		return ""
	}}
}




function RUST-Is-Available {
	$__program = Get-Command rustup -ErrorAction SilentlyContinue
	if (-not $__program) {
		return 1
	}

	$__program = Get-Command rustc -ErrorAction SilentlyContinue
	if (-not $__program) {
		return 1
	}

	$__program = Get-Command cargo -ErrorAction SilentlyContinue
	if (-not $__program) {
		return 1
	}

	return 0
}




function RUST-Is-Localized {
	if (-not [string]::IsNullOrEmpty($env:PROJECT_RUST_LOCALIZED)) {
		return 0
	}

	return 1
}




function RUST-Setup-Local-Environment {
	# validate input
	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_ROOT)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_TOOLS)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_AUTOMATA)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_PATH_RUST_ENGINE)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_OS)) {
		return 1
	}

	if ([string]::IsNullOrEmpty($env:PROJECT_ARCH)) {
		return 1
	}

	$__process = RUST-Is-Localized
	if ($__process -eq 0) {
		return 0
	}


	# execute
	$__label = "($env:PROJECT_PATH_RUST_ENGINE)"
	$__location = "$(RUST-Get-Activator-Path)"
	$env:CARGO_HOME = Split-Path -Parent -Path "${__location}"
	$env:RUSTUP_HOME = Split-Path -Parent -Path "${__location}"

	## download installer from official portal
	$null = Invoke-Expression "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\rust-rustup.ps1"

	## it's a clean repo. Start setting up localized environment...
	$null = FS-Make-Housing-Directory "${__location}"
	$null = FS-Write-File "${__location}" @"
function deactivate {
	`$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") ``
		+ ";" ``
		+ [System.Environment]::GetEnvironmentVariable("Path","User")
	`${env:PROJECT_RUST_LOCALIZED} = `$null
	`${env:CARGO_HOME} = `$null
	`${env:RUSTUP_HOME} = `$null
	Copy-Item -Path Function:_OLD_PROMPT -Destination Function:prompt
	Remove-Item -Path Function:_OLD_PROMPT
}

# activate
`${env:CARGO_HOME} = "${CARGO_HOME}"
`${env:RUSTUP_HOME} = "${RUSTUP_HOME}"
`${env:PROJECT_RUST_LOCALIZED} = "${__location}"
`$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") ``
	+ ";" ``
	+ [System.Environment]::GetEnvironmentVariable("Path","User") ``
	+ ";" ``
	+ "${CARGO_HOME}\bin"
Copy-Item -Path function:prompt -Destination function:_OLD_PROMPT
function global:prompt {
	Write-Host -NoNewline -ForegroundColor Green "(${__label}) "
	_OLD_VIRTUAL_PROMPT
}
"@

	if (-not (Test-Path "${__location}")) {
		return 1
	}


	# testing the activation
	$__process = RUST-Activate-Local-Environment
	if ($__process -ne 0) {
		return 1
	}


	# setup localized compiler
	$__target = RUST-Get-Build-Target "${env:PROJECT_OS}" "${env:PROJECT_ARCH}"
	$__process = OS-Exec "rustup" "target add ${__target}"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "rustup" "component add llvm-tools-preview"
	if ($__process -ne 0) {
		return 1
	}

	$__process = OS-Exec "cargo" "install grcov"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}
