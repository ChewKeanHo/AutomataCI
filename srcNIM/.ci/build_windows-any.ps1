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




# initialize
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from ci.cmd instead!\n"
	return 1
}

. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\os.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\io\fs.ps1"
. "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_AUTOMATA}\services\compilers\nim.ps1"




# safety checking control surfaces
OS-Print-Status info "checking nim availability..."
$__process = NIM-Is-Available
if ($__process -ne 0) {
	OS-Print-Status error "missing nim compiler."
	return 1
}


OS-Print-Status info "activating local environment..."
$__process = NIM-Activate-Local-Environment
if ($__process -ne 0) {
	OS-Print-Status error "activation failed."
	return 1
}


OS-Print-Status info "prepare nim workspace..."
$__build = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
$__source = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_NIM}"
$__main = "${__source}\${env:PROJECT_SKU}.nim"

$SETTINGS_CC = `
	"compileToC " `
	+ "--passC:-Wall --passL:-Wall " `
	+ "--passC:-Wextra --passL:-Wextra " `
	+ "--passC:-std=gnu89 --passL:-std=gnu89 " `
	+ "--passC:-pedantic --passL:-pedantic " `
	+ "--passC:-Wstrict-prototypes --passL:-Wstrict-prototypes " `
	+ "--passC:-Wold-style-definition --passL:-Wold-style-definition " `
	+ "--passC:-Wundef --passL:-Wundef " `
	+ "--passC:-Wno-trigraphs --passL:-Wno-trigraphs " `
	+ "--passC:-fno-strict-aliasing --passL:-fno-strict-aliasing " `
	+ "--passC:-fno-common --passL:-fno-common " `
	+ "--passC:-fshort-wchar --passL:-fshort-wchar " `
	+ "--passC:-fstack-protector-all --passL:-fstack-protector-all " `
	+ "--passC:-Werror-implicit-function-declaration --passL:-Werror-implicit-function-declaration " `
	+ "--passC:-Wno-format-security --passL:-Wno-format-security " `
	+ "--passC:-Os --passL:-Os " `
	+ "--passC:-g0 --passL:-g0 " `
	+ "--passC:-flto --passL:-flto "

$SETTINGS_NIM = "--mm:orc " `
	+ "--define:release " `
	+ "--opt:size " `
	+ "--colors:on " `
	+ "--styleCheck:off " `
	+ "--showAllMismatches:on " `
	+ "--tlsEmulation:on " `
	+ "--implicitStatic:on " `
	+ "--trmacros:on " `
	+ "--panics:on "

$null = FS-Make-Directory "${__build}"




# checking nim package health
OS-Print-Status info "checking nim package health..."
$__process = NIM-Check-Package "${__source}"
if ($__process -ne 0) {
	OS-Print-Status error "check failed."
	return 1
}




# building linux-amd64
$__compiler = "x86_64-linux-gnu-gcc"
OS-Print-Status info "compiling linux-amd64 with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if (($__process -eq 0) -and (-not ("${env:PROJECT_OS}" -eq "darwin"))) {
	$__target = "${env:PROJECT_SKU}_linux-amd64"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--amd64.linux.gcc.exe:`"${__compiler}`" " `
		+ "--amd64.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:amd64 " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-arm64
$__compiler = "aarch64-linux-gnu-gcc"
OS-Print-Status info "compiling linux-arm64 with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if (($__process -eq 0) -and (-not ("${env:PROJECT_OS}" -eq "darwin"))) {
	$__target = "${env:PROJECT_SKU}_linux-arm64"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--arm64.linux.gcc.exe:`"${__compiler}`" " `
		+ "--arm64.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:arm64 " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building windows-amd64
$__compiler = "x86_64-w64-mingw32-gcc"
OS-Print-Status info "compiling windows-amd64 with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_windows-amd64"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--amd64.windows.gcc.exe:`"${__compiler}`" " `
		+ "--amd64.windows.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:windows " `
		+ "--cpu:amd64 " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building windows-arm64
$__compiler = "x86_64-w64-mingw32-gcc"
OS-Print-Status info "compiling windows-arm64 with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_windows-arm64"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--arm64.windows.gcc.exe:`"${__compiler}`" " `
		+ "--arm64.windows.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:windows " `
		+ "--cpu:arm64 " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-armel
$__compiler = "arm-linux-gnueabi-gcc"
OS-Print-Status info "compiling linux-armel with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-armel"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--arm.linux.gcc.exe:`"${__compiler}`" " `
		+ "--arm.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:arm " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-armhf
$__compiler = "arm-linux-gnueabihf-gcc"
OS-Print-Status info "compiling linux-armhf with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-armhf"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--arm.linux.gcc.exe:`"${__compiler}`" " `
		+ "--arm.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:arm " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-mips
$__compiler = "mips-linux-gnu-gcc"
OS-Print-Status info "compiling linux-mips with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-mips"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--mips.linux.gcc.exe:`"${__compiler}`" " `
		+ "--mips.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:mips " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-mipsle
$__compiler = "mipsel-linux-gnu-gcc"
OS-Print-Status info "compiling linux-mipsle with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-mipsle"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--mipsel.linux.gcc.exe:`"${__compiler}`" " `
		+ "--mipsel.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:mipsel " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-mips64
$__compiler = "mips64-linux-gnu-gcc"
OS-Print-Status info "compiling linux-mips64 with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-mips64"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--mips64.linux.gcc.exe:`"${__compiler}`" " `
		+ "--mips64.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:mips64 " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-mips64le
$__compiler = "mips64el-linux-gnu-gcc"
OS-Print-Status info "compiling linux-mips64le with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-mips64le"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--mips64el.linux.gcc.exe:`"${__compiler}`" " `
		+ "--mips64el.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:mips64el " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-mips64r6
$__compiler = "mipsisa64r6-linux-gnu-gcc"
OS-Print-Status info "compiling linux-mips64r6 with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-mips64r6"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--mips64.linux.gcc.exe:`"${__compiler}`" " `
		+ "--mips64.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:mips64 " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-mips64r6le
$__compiler = "mipsisa64r6el-linux-gnuabi64-gcc"
OS-Print-Status info "compiling linux-mips64r6le with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-mips64r6le"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--mips64el.linux.gcc.exe:`"${__compiler}`" " `
		+ "--mips64el.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:mips64el " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-powerpc
$__compiler = "powerpc-linux-gnu-gcc"
OS-Print-Status info "compiling linux-powerpc with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-powerpc"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--powerpc.linux.gcc.exe:`"${__compiler}`" " `
		+ "--powerpc.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:powerpc " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-ppc64le
$__compiler = "powerpc64le-linux-gnu-gcc"
OS-Print-Status info "compiling linux-ppc64le with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-ppc64le"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:gcc " `
		+ "--passC:-static --passL:-static " `
		+ "--passC:-s --passL:-s " `
		+ "--powerpc64el.linux.gcc.exe:`"${__compiler}`" " `
		+ "--powerpc64el.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:powerpc64el " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building linux-riscv64
$__compiler = "'disabled'"
OS-Print-Status info "compiling linux-riscv64 with ${__compiler}..."
$__process = OS-Is-Command-Available "${__compiler}"
if ($__process -eq 0) {
	$__target = "${env:PROJECT_SKU}_linux-riscv64"
	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
		+ "--cc:clang " `
		+ "--riscv64.linux.gcc.exe:`"${__compiler}`" " `
		+ "--riscv64.linux.gcc.linkerexe:`"${__compiler}`" " `
		+ "--os:linux " `
		+ "--cpu:riscv64 " `
		+ "--out:`"${__build}\${__target}`" " `
		+ "${__main}"
	$__process = OS-Exec "nim" "${__arguments}"
	if ($__process -ne 0) {
		OS-Print-Status error "build failed."
		return 1
	}
} else {
	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
}




# building js-wasm
#$__compiler = "emcc"
#OS-Print-Status info "compiling js-wasm with ${__compiler}..."
#$__process = OS-Is-Command-Available "${__compiler}"
#if ($__process -eq 0) {
#	$__target = "${env:PROJECT_SKU}_js-wasm.wasm"
#	$__arguments = "${SETTINGS_CC} ${SETTINGS_NIM} " `
#		+ "--cc:clang " `
#		+ "--clang.exe:`"${__compiler}`" " `
#		+ "--clang.linkerexe:`"${__compiler}`" " `
#		+ "--os:linux " `
#		+ "--out:`"${__build}\${__target}`" " `
#		+ "${__main}"
#	$__process = OS-Exec "nim" "${__arguments}"
#	if ($__process -ne 0) {
#		OS-Print-Status error "build failed."
#		return 1
#	}
#} else {
#	OS-Print-Status warning "compilation skipped. Cross-compile is unavailable."
#}




# building js-js
OS-Print-Status info "compiling js-js..."
$__target = "${env:PORJECT_SKU}_js-js.js"
$__process = OS-Exec "nim" "js ${SETTINGS_NIM} --out:`"${__build}\${__target}`" `"${__main}`""
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# placeholding source code flag
$__file = "${env:PROJECT_SKU}-src_any-any"
OS-Print-Status info "building output file: ${__file}"
$__process = FS-Touch-File "${__build}\${__file}"
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# placeholding homebrew flag
$__file = "${env:PROJECT_SKU}-homebrew_any-any"
OS-Print-Status info "building output file: ${__file}"
$__process = FS-Touch-File "${__build}\${__file}"
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# placeholding chocolatey flag
$__file = "${env:PROJECT_SKU}-chocolatey_any-any"
OS-Print-Status info "building output file: ${__file}"
$__process = FS-Touch-File "${__build}\${__file}"
if ($__process -ne 0) {
	OS-Print-Status error "build failed."
	return 1
}




# report status
return 0
