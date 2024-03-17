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




function C-Get-Compiler {
	param(
		[string]$___os,
		[string]$___arch,
		[string]$___base_os,
		[string]$___base_arch,
		[string]$___compiler
	)


	# execute
	if ($(STRINGS-Is-Empty "${___compiler}") -ne 0) {
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return "${___compiler}"
		}
	}

	switch ("${___os}-${___arch}") {
	{ $_ -in "darwin-amd64", "darwin-arm64" } {
		$___compiler = "clang-17"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "clang-15"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "clang-14"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "clang"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "js-wasm" {
		$___compiler = "emcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}
	} "linux-amd64" {
		$___compiler = "arm-linux-gnueabi-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-arm64" {
		$___compiler = "aarch64-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-arm", "linux-armel", "linux-armle" } {
		$___compiler = "arm-linux-gnueabi-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "arm-linux-eabi-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-armhf" {
		$___compiler = "arm-linux-gnueabihf-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-i386" {
		$___compiler = "i686-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "i686-elf-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-mips" {
		$___compiler = "mips-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mipsle", "linux-mipsel" } {
		$___compiler = "mipsel-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-mips64" {
		$___compiler = "mips64-linux-gnuabi64-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips64le", "linux-mips64el" } {
		$___compiler = "mips64el-linux-gnuabi64-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips32r6", "linux-mipsisa32r6" } {
		$___compiler = "mipsisa32r6-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips64r6", "linux-mipsisa64r6" } {
		$___compiler = "mipsisa64r6-linux-gnuabi64-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips32r6le", "linux-mipsisa32r6le", "linux-mipsisa32r6el" } {
		$___compiler = "mipsisa32r6el-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-mips64r6le", "linux-mipsisa64r6le", "linux-mipsisa64r6el" } {
		$___compiler = "mipsisa64r6el-linux-gnuabi64-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "linux-powerpc" {
		$___compiler = "powerpc-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { $_ -in "linux-ppc64le", "linux-ppc64el" } {
		$___compiler = "powerpc64le-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { "linux-riscv64" } {
		$___compiler = "riscv64-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "riscv64-elf-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { "linux-s390x" } {
		$___compiler = "s390x-linux-gnu-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "gcc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} { "none-avr" } {
		$___compiler = "avr-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}
	} "windows-amd64" {
		$___compiler = "x86_64-w64-mingw32-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}

		$___compiler = "mingw64"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}


		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "cc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "windows-i386" {
		$___compiler = "i686-w64-mingw32-gcc"
		$___process = OS-Is-Command-Available "${___compiler}"
		if ($___process -eq 0) {
			return $___compiler
		}


		if (("${___os}" -eq "${___base_os}") -and
			("${___arch}" -eq "${___base_arch}")) {
			$___compiler = "cc"
			$___process = OS-Is-Command-Available "${___compiler}"
			if ($___process -eq 0) {
				return $___compiler
			}
		}
	} "wasip1-wasm" {
		# let it fail
	} default {
		# let it fail
	}}


	# report status
	return ""
}




function C-Get-Strict-Settings {
	return " -Wall" `
		+ " -Wextra" `
		+ " -std=gnu89" `
		+ " -pedantic" `
		+ " -Wstrict-prototypes" `
		+ " -Wold-style-definition" `
		+ " -Wundef" `
		+ " -Wno-trigraphs" `
		+ " -fno-strict-aliasing" `
		+ " -fno-common" `
		+ " -fshort-wchar" `
		+ " -fstack-protector-all" `
		+ " -Werror-implicit-function-declaration" `
		+ " -Wno-format-security" `
		+ " -pie -fPIE"
}




function C-Is-Available {
	$null = OS-Sync


	$___process = C-Get-Compiler "${env:PROJECT_OS}" "${env:PROJECT_ARCH}"
	if ($(STRINGS-Is-Empty "${___process}") -ne 0) {
		return 1
	}


	# report status
	return 0
}




function C-Setup {
	# validate input
	$___process = C-Is-Available
	if ($___process -eq 0) {
		return 0
	}

	$___process =  OS-Is-Command-Available "choco"
	if ($___process -ne 0) {
		return 1
	}


	# execute
	$___process = OS-Exec "choco" "install gcc-arm-embedded -y"
	if ($___process -ne 0) {
		return 1
	}

	if ($(STRINGS-Is-Empty "$(C-Get-Compiler "windows" "amd64")") -eq 0) {
		$___process = OS-Exec "choco" "install mingw -y"
		if ($___process -ne 0) {
			return 1
		}
	}

	if ($(STRINGS-Is-Empty "$(C-Get-Compiler "js" "wasm")") -eq 0) {
		# BUG: choco fails to install emscripten's dependency properly (git.install)
		#      See: https://github.com/aminya/chocolatey-emscripten/issues/2
		#$___process = OS-Exec "choco" "install emscripten -y"
		#if ($___process -ne 0) {
		#	return 1
		#}
	}

	$null = OS-Sync


	# report status
	return 0
}
