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
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"




function REPREPRO-Create-Conf {
	param(
		[string]$__directory,
		[string]$__codename,
		[string]$__suite,
		[string]$__components,
		[string]$__architectures,
		[string]$__gpg
	)


	# validate input
	if ([string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__codename) -or
		[string]::IsNullOrEmpty($__suite) -or
		[string]::IsNullOrEmpty($__components)) {
		return 1
	}


	# execute
	$__filename = "${__directory}\conf\distributions"
	$null = FS-Make-Housing-Directory "${__filename}"
	$null = FS-Remove-Silently "${__filename}"
	if ([string]::IsNullOrEmpty($__gpg)) {
		$__process = FS-Write-File "${__filename}" @"
Codename: ${__codename}
Suite: ${__suite}
Components: ${__components}
Architectures:
"@
		if ($__process -ne 0) {
			return 1
		}
	} else {
		$__process = FS-Write-File "${__filename}" @"
Codename: ${__codename}
Suite: ${__suite}
Components: ${__components}
SignWith: ${__gpg}
Architectures:
"@
		if ($__process -ne 0) {
			return 1
		}
	}


	if ([string]::IsNullOrEmpty($__architectures)) {
		$__architectures = @(
			"armhf", "armel", "mipsn32", "mipsn32el", "mipsn32r6",
			"mipsn32r6el", "mips64", "mips64el", "mips64r6", "mips64r6el",
			"powerpcspe", "x32", "arm64ilp32", "alpha", "amd64",
			"arc", "armeb", "arm", "arm64", "avr32",
			"hppa", "loong64", "i386", "ia64", "m32r",
			"m68k", "mips", "mipsel", "mipsr6", "mipsr6el",
			"nios2", "or1k", "powerpc", "powerpcel", "ppc64",
			"ppc64el", "riscv64", "s390", "s390x", "sh3",
			"sh3eb", "sh4", "sh4eb", "sparc", "sparc64",
			"tilegx")
		$__oses = @(
			"linux", "kfreebsd", "knetbsd", "kopensolaris", "hurd",
			"darwin", "dragonflybsd", "freebsd", "netbsd", "openbsd",
			"aix", "solaris")

		foreach ($__arch in $__architectures) {
			$null = FS-Append-File "${__filename}" " ${__arch}"
			foreach ($__os in $__oses) {
				$null = FS-Append-File "${__filename}" " ${__os}-${__arch}"
			}
		}

		$null = FS-Append-File "${__filename}" "`n"
	} else {
		$null = FS-Append-File "${__filename}" " ${__architectures}`n"
	}


	# report status
	return 0
}




function REPREPRO-Is-Available {
	# execute
	$__process = OS-Is-Command-Available "reprepro"
	if ($__process -ne 0) {
		return 1
	}


	# report status
	return 0
}




function REPREPRO-Publish {
	param (
		[string]$__target,
		[string]$__directory,
		[string]$__datastore,
		[string]$__db_directory,
		[string]$__codename
	)


	# validate input
	if ([string]::IsNullOrEmpty($__target) -or
		[string]::IsNullOrEmpty($__directory) -or
		[string]::IsNullOrEmpty($__datastore) -or
		[string]::IsNullOrEmpty($__codename) -or
		(-not (Test-Path "${__directory}" -PathType Container))) {
		return 1
	}


	# execute
	$null = FS-Make-Directory "${__db_directory}"
	$null = FS-Make-Directory "${__directory}"
	$null = FS-Make-Directory "${__datastore}"
	$__arguments = "--basedir `"${__datastore}`" " `
			+ "--dbdir `"${__db_directory}`" " `
			+ "--outdir `"${__directory}`" " `
			+ "includedeb `"${__codename}`" " `
			+ "`"${__target}`""
	$__process = OS-Exec "reprepro" "${__arguments}"


	# report status
	if ($__process -eq 0) {
		return 0
	}

	return 1
}




function REPREPRO-Setup {
	return 0  # Windows do not have Reprepro
}
