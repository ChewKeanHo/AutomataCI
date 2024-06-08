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
. "${env:LIBS_AUTOMATACI}\services\io\os.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"




function RUST-Activate-Local-Environment {
	# validate input
	$___process = RUST-Is-Localized
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___location = "$(RUST-Get-Activator-Path)"
	$___process = FS-Is-File "${___location}"
	if ($___process -ne 0) {
		return 1
	}

	. $___location
	$___process = RUST-Is-Localized
	if ($___process -eq 0) {
		return 0
	}


	# report status
	return 1
}




function RUST-Cargo-Login {
	# validate input
	if (($(STRINGS-Is-Empty "${env:CARGO_REGISTRY}") -eq 0) -or
		($(STRINGS-Is-Empty "${env:CARGO_PASSWORD}") -eq 0)) {
		return 1
	}


	# execute
	$___arguments = "login " `
		+ "--registry `"${env:CARGO_REGISTRY}`" " `
		+ "`"${env:CARGO_PASSWORD}`" "
	$___process = OS-Exec "cargo" "${___arguments}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Cargo-Logout {
	# execute
	$___process = OS-Exec "cargo" "logout"
	if ($___process -ne 0) {
		return 1
	}

	$null = FS-Remove-Silently "\.cargo\credentials.toml"


	# report status
	return 0
}




function RUST-Cargo-Release-Crate {
	param(
		[string]$___source_directory
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___source_directory}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___source_directory}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___current_path = Get-Location
	$null = Set-Location "${___source_directory}"
	$___process = OS-Exec "cargo" "publish"
	$null = Set-Location "${___current_path}"
	$null = Remove-Variable ___current_path

	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Crate-Is-Valid {
	param(
		[string]$___target
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___target}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___target}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = STRINGS-Has-Prefix "cargo" (Split-Path -Leaf -Path "${___target}")
	if ($___process -ne 0) {
		return 1
	}

	$___hasCARGO = "false"
	foreach ($___file in (Get-ChildItem -Path ${___target})) {
		if ($___file.Name -eq "Cargo.toml") {
			$___hasCARGO = "true"
		}
	}
	if ($___hasCARGO -eq "true") {
		return 0
	}


	# report status
	return 1
}




function RUST-Create-Archive {
	param(
		[string]$___source_directory,
		[string]$___target_directory
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___source_directory}") -eq 0) -or
		($(STRINGS-Is-Empty "${___target_directory}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-Directory "${___source_directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = FS-Is-Directory "${___target_directory}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = RUST-Activate-Local-Environment
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Remove-Silently "${___source_directory}\Cargo.lock"

	$___current_path = Get-Location
	$null = Set-Location "${___source_directory}"

	$___process = OS-Exec "cargo" "build"
	if ($___process -ne 0) {
		$null = Set-Location "${___current_path}"
		$null = Remove-Variable ___current_path
		return 1
	}

	$___process = OS-Exec "cargo" "publish --dry-run"
	if ($___process -ne 0) {
		$null = Set-Location "${___current_path}"
		$null = Remove-Variable ___current_path
		return 1
	}

	$null = Set-Location "${___current_path}"
	$null = Remove-Variable ___current_path

	$null = FS-Remove-Silently "${___source_directory}\target"
	$null = FS-Remake-Directory "${___target_directory}"
	$___process = FS-Copy-All "${___source_directory}\" "${___target_directory}"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Create-CARGO-TOML {
	param(
		[string]$___filepath,
		[string]$___template,
		[string]$___sku,
		[string]$___version,
		[string]$___pitch,
		[string]$___edition,
		[string]$___license,
		[string]$___docs,
		[string]$___website,
		[string]$___repo,
		[string]$___readme,
		[string]$___contact_name,
		[string]$___contact_email
	)


	# validate input
	if (($(STRINGS-Is-Empty "${___filepath}") -eq 0) -or
		($(STRINGS-Is-Empty "${___template}") -eq 0) -or
		($(STRINGS-Is-Empty "${___sku}") -eq 0) -or
		($(STRINGS-Is-Empty "${___version}") -eq 0) -or
		($(STRINGS-Is-Empty "${___pitch}") -eq 0) -or
		($(STRINGS-Is-Empty "${___edition}") -eq 0) -or
		($(STRINGS-Is-Empty "${___license}") -eq 0) -or
		($(STRINGS-Is-Empty "${___docs}") -eq 0) -or
		($(STRINGS-Is-Empty "${___website}") -eq 0) -or
		($(STRINGS-Is-Empty "${___repo}") -eq 0) -or
		($(STRINGS-Is-Empty "${___readme}") -eq 0) -or
		($(STRINGS-Is-Empty "${___contact_name}") -eq 0) -or
		($(STRINGS-Is-Empty "${___contact_email}") -eq 0)) {
		return 1
	}

	$___process = FS-Is-File "${___template}"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$null = FS-Remove-Silently "${___filepath}"
	$___process = FS-Write-File "${___filepath}" @"
[package]
name = '${___sku}'
version = '${___version}'
description = '${___pitch}'
edition = '${___edition}'
license = '${___license}'
documentation = '${___docs}'
homepage = '${___website}'
repository = '${___repo}'
readme = '${___readme}'
authors = [ '${___contact_name} <${___contact_email}>' ]





"@
	if ($___process -ne 0) {
		return 1
	}


	$___begin_append = 1
	foreach ($___line in (Get-Content "${___template}")) {
		if (($___begin_append -ne 0) -and
			($("${___line}" -replace '\[AUTOMATACI BEGIN\]') -ne "${___line}")) {
			$___begin_append = 0
			continue
		}

		if ($___begin_append -ne 0) {
			continue
		}

		$___process = FS-Append-File "${___filepath}" "${___line}`n"
		if ($___process -ne 0) {
			return 1
		}
	}


	# update Cargo.lock
	$___process = RUST-Activate-Local-Environment
	if ($___process -ne 0) {
		return 1
	}

	$___current_path = Get-Location
	$null = Set-Location (Split-Path -Parent -Path "${___filepath}")
	$___process = OS-Exec "cargo" "update"
	if ($___process -ne 0) {
		$null = Set-Location "${___current_path}"
		$null = Remove-Variable ___current_path
		return 1
	}

	$___process = OS-Exec "cargo" "clean"
	$null = Set-Location "${___current_path}"
	$null = Remove-Variable ___current_path
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Get-Activator-Path {
	# execute
	return "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_TOOLS}" `
		+ "\${env:PROJECT_PATH_RUST_ENGINE}\Activate.ps1"
}




function RUST-Get-Build-Target {
	param(
		[string]$___os,
		[string]$___arch
	)


	# execute
	switch ("${___os}-${___arch}") {
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
	# execute
	$___process = OS-Is-Command-Available "rustup"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "rustc"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Is-Command-Available "cargo"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function RUST-Is-Localized {
	# execute
	if ($(STRINGS-Is-Empty "${env:PROJECT_RUST_LOCALIZED}") -ne 0) {
		return 0
	}


	# report status
	return 1
}




function RUST-Setup-Local-Environment {
	# validate input
	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_ROOT}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_TOOLS}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_AUTOMATA}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_PATH_RUST_ENGINE}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_OS}") -eq 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "${env:PROJECT_ARCH}") -eq 0) {
		return 1
	}

	$___process = RUST-Is-Localized
	if ($___process -eq 0) {
		return 0
	}


	# execute
	$___label = "($env:PROJECT_PATH_RUST_ENGINE)"
	$___location = "$(RUST-Get-Activator-Path)"
	$env:CARGO_HOME = Split-Path -Parent -Path "${___location}"
	$env:RUSTUP_HOME = Split-Path -Parent -Path "${___location}"

	## download installer from official portal
	$null = Invoke-Expression "${env:LIBS_AUTOMATACI}\services\compilers\rust-rustup.ps1"

	## it's a clean repo. Start setting up localized environment...
	$null = FS-Make-Housing-Directory "${___location}"
	$null = FS-Write-File "${___location}" @"
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


# check existing
if (-not [string]::IsNullOrEmpty(`${env:PROJECT_RUST_LOCALIZED})) {
	return
}


# activate
`${env:CARGO_HOME} = "${CARGO_HOME}"
`${env:RUSTUP_HOME} = "${RUSTUP_HOME}"
`${env:PROJECT_RUST_LOCALIZED} = "${___location}"
`$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") ``
	+ ";" ``
	+ [System.Environment]::GetEnvironmentVariable("Path","User") ``
	+ ";" ``
	+ "${CARGO_HOME}\bin"
Copy-Item -Path function:prompt -Destination function:_OLD_PROMPT
function global:prompt {
	Write-Host -NoNewline -ForegroundColor Green "(${___label}) "
	_OLD_VIRTUAL_PROMPT
}
"@

	$___process = FS-Is-File "${___location}"
	if ($___process -ne 0) {
		return 1
	}


	# testing the activation
	$___process = RUST-Activate-Local-Environment
	if ($___process -ne 0) {
		return 1
	}


	# setup localized compiler
	$___target = RUST-Get-Build-Target "${env:PROJECT_OS}" "${env:PROJECT_ARCH}"
	$___process = OS-Exec "rustup" "target add ${___target}"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Exec "rustup" "component add llvm-tools-preview"
	if ($___process -ne 0) {
		return 1
	}

	$___process = OS-Exec "cargo" "install grcov"
	if ($___process -ne 0) {
		return 1
	}


	# report status
	return 0
}
