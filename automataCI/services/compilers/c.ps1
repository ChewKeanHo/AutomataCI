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




function C-Get-Compiler {
	param(
		[string]$__os,
		[string]$__arch,
		[string]$__base_os,
		[string]$__base_arch,
		[string]$__compiler
	)


	# execute
	if ([string]::IsNullOrEmpty($__compiler)) {
		$__process = OS-Is-Command-Available "${__compiler}"
		if ($__process -eq 0) {
			return "${__compiler}"
		}
	}

	$__compiler = C-Get-Compiler-By-Arch "${__os}" "${__arch}"
	if (-not [string]::IsNullOrEmpty($__compiler)) {
		if (("${__os}" -eq "darwin") -and ("${__base_os}" -ne "darwin")) {
			# MacOS binary is best built on MacOS itself due to
			# Apple SDK is only available on MacOS
			return ""
		}

		return "${__compiler}"
	}

	$__compiler = C-Get-Compiler-Common `
		"${__os}" `
		"${__arch}" `
		"${__base_os}" `
		"${__base_arch}"
	if ($__compiler -eq 0) {
		return "${__compiler}"
	}


	# report status
	return ""
}




function C-Get-Compiler-By-Arch {
	param(
		[string]$__os,
		[string]$__arch
	)


	# execute
	switch ($__arch) {
	amd64 {
		switch ($__os) {
		windows {
			$__compiler = "x86_64-w64-mingw32-gcc"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "mingw64"
		} darwin {
			$__compiler = "clang-17"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "clang-15"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "clang-14"
		} default {
			$__compiler = "x86_64-linux-gnu-gcc"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "x86_64-elf-gcc"
		}}
	} {$_ -in "arm", "armel"} {
		$__compiler = "arm-linux-gnueabi-gcc"
		$__process = OS-Is-Command-Available "${__compiler}"
		if ($__process -eq 0) {
			return $__compiler
		}

		$__compiler = "arm-none-gnueabi-gcc"
	} armhf {
		$__compiler = "arm-linux-gnueabihf-gcc"
	} arm64 {
		switch ($__os) {
		windows {
			$__compiler = "x86_64-w64-mingw32-gcc"
		} darwin {
			$__compiler = "clang-17"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "clang-15"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "clang-14"
		} default {
			$__compiler = "aarch64-linux-gnu-gcc"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "aarch64-elf-gcc"
		}}
	} avr {
		$__compiler = "avr-gcc"
		$__process = OS-Is-Command-Available "${__compiler}"
		if ($__process -eq 0) {
			return $__compiler
		}

		$__compiler = "clang-17"
		$__process = OS-Is-Command-Available "${__compiler}"
		if ($__process -eq 0) {
			return $__compiler
		}

		$__compiler = "clang-15"
		$__process = OS-Is-Command-Available "${__compiler}"
		if ($__process -eq 0) {
			return $__compiler
		}

		$__compiler = "clang-14"
	} i386 {
		switch ($__os) {
		windows {
			$__compiler = "x86_64-w64-mingw32-gcc"
		} darwin {
			$__compiler = "clang-17"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "clang-15"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "clang-14"
		} default {
			$__compiler = "i686-linux-gnu-gcc"
			$__process = OS-Is-Command-Available "${__compiler}"
			if ($__process -eq 0) {
				return $__compiler
			}

			$__compiler = "i686-elf-gcc"
		}}
	} mips {
		$__compiler = "mips-linux-gnu-gcc"
	} { $_ -in "mipsle", "mipsel" } {
		$__compiler = "mipsel-linux-gnu-gcc"
	} mips64 {
		$__compiler = "mips64-linux-gnuabi64-gcc"
	} { $_ -in "mips64le", "mips64el" } {
		$__compiler = "mips64el-linux-gnuabi64-gcc"
	} mipsisa32r6 {
		$__compiler = "mipsisa32r6-linux-gnu-gcc"
	} { $_ -in "mips64r6", "mipsisa64r6" } {
		$__compiler = "mipsisa64r6-linux-gnuabi64-gcc"
	} { $_ -in "mips32r6le", "mipsisa32r6le", "mipsisa32r6el" } {
		$__compiler = "mipsisa32r6el-linux-gnu-gcc"
	} { $_ -in "mips64r6le", "mips64r6el", "mipsisa64r6el" } {
		$__compiler = "mipsisa64r6el-linux-gnuabi64-gcc"
	} powerpc {
		$__compiler = "powerpc-linux-gnu-gcc"
	} { $_ -in "ppc64le", "ppc64el" } {
		$__compiler = "powerpc64le-linux-gnu-gcc"
	} riscv64 {
		$__compiler = "riscv64-elf-gcc"
	} s390x {
		$__compiler = "s390x-linux-gnu-gcc"
	} wasm {
		$__compiler = "emcc"
	} default {
	}}

	$__process = OS-Is-Command-Available "${__compiler}"
	if ($__process -eq 0) {
		return $__compiler
	}


	# report status
	return ""
}




function C-Get-Compiler-Common {
	param(
		[string]$__os,
		[string]$__arch,
		[string]$__base_os,
		[string]$__base_arch
	)


	# execute
	if ("${__arch}" -ne "${__base_arch}") {
		return ""
	}

	$__compiler = "gcc"
	$__process = OS-Is-Command-Available "${__compiler}"
	if ($__process -eq 0) {
		return $__compiler
	}

	$__compiler = "cc"
	$__process = OS-Is-Command-Available "${__compiler}"
	if ($__process -eq 0) {
		return $__compiler
	}

	$__compiler = "clang17"
	$__process = OS-Is-Command-Available "${__compiler}"
	if ($__process -eq 0) {
		return $__compiler
	}

	$__compiler = "clang15"
	$__process = OS-Is-Command-Available "${__compiler}"
	if ($__process -eq 0) {
		return $__compiler
	}

	$__compiler = "clang14"
	$__process = OS-Is-Command-Available "${__compiler}"
	if ($__process -eq 0) {
		return $__compiler
	}

	$__compiler = "clang"
	$__process = OS-Is-Command-Available "${__compiler}"
	if ($__process -eq 0) {
		return $__compiler
	}


	# report status
	return ""
}




function C-Get-Strict-Settings {
	return "-Wall" `
		+ "-Wextra" `
		+ "-std=gnu89" `
		+ "-pedantic" `
		+ "-Wstrict-prototypes" `
		+ "-Wold-style-definition" `
		+ "-Wundef" `
		+ "-Wno-trigraphs" `
		+ "-fno-strict-aliasing" `
		+ "-fno-common" `
		+ "-fshort-wchar" `
		+ "-fstack-protector-all" `
		+ "-Werror-implicit-function-declaration" `
		+ "-Wno-format-security" `
		+ "-pie -fPIE"
}




function C-Is-Available {
	if (-not ([string]::IsNullOrEmpty($(C-Get-Compiler-By-Arch "windows" "amd64"))) -and
		(-not [string]::IsNullOrEmpty($(C-Get-Compiler-By-Arch "" "wasm"))) -and
		(-not [string]::IsNullOrEmpty($(C-Get-Compiler-By-Arch "windows" "arm64")))) {
		return 0
	}

	return 1
}
