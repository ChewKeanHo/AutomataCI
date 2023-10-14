#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                 http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/compilers/nim.sh"




# safety check control surfaces
OS::print_status info "checking nim availability...\n"
NIM::is_available
if [ $? -ne 0 ]; then
        OS::print_status error "missing nim compiler.\n"
        return 1
fi


OS::print_status info "activating local environment...\n"
NIM::activate_local_environment
if [ $? -ne 0 ]; then
        OS::print_status error "activation failed.\n"
        return 1
fi


OS::print_status info "prepare nim workspace...\n"
__build="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
__source="${PROJECT_PATH_ROOT}/${PROJECT_NIM}"
__main="${__source}/${PROJECT_SKU}.nim"

SETTINGS_CC="\
compileToC \
--passC:-Wall --passL:-Wall \
--passC:-Wextra --passL:-Wextra \
--passC:-std=gnu89 --passL:-std=gnu89 \
--passC:-pedantic --passL:-pedantic \
--passC:-Wstrict-prototypes --passL:-Wstrict-prototypes \
--passC:-Wold-style-definition --passL:-Wold-style-definition \
--passC:-Wundef --passL:-Wundef \
--passC:-Wno-trigraphs --passL:-Wno-trigraphs \
--passC:-fno-strict-aliasing --passL:-fno-strict-aliasing \
--passC:-fno-common --passL:-fno-common \
--passC:-fshort-wchar --passL:-fshort-wchar \
--passC:-fstack-protector-all --passL:-fstack-protector-all \
--passC:-Werror-implicit-function-declaration --passL:-Werror-implicit-function-declaration \
--passC:-Wno-format-security --passL:-Wno-format-security \
--passC:-Os --passL:-Os \
--passC:-g0 --passL:-g0 \
--passC:-flto --passL:-flto \
"
SETTINGS_NIM="\
--mm:orc \
--define:release \
--opt:size \
--colors:on \
--styleCheck:off \
--showAllMismatches:on \
--tlsEmulation:on \
--implicitStatic:on \
--trmacros:on \
--panics:on \
"

FS::make_directory "$__build"




# checking nim package health
OS::print_status info "checking nim package health...\n"
NIM::check_package "$__source"
if [ $? -ne 0 ]; then
        OS::print_status error "check failed.\n"
        return 1
fi




# building linux-amd64
__compiler="x86_64-linux-gnu-gcc"
OS::print_status info "compiling linux-amd64 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ] && [ ! "$PROJECT_OS" = "darwin" ]; then
        __target="${PROJECT_SKU}_linux-amd64"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --amd64.linux.gcc.exe:"$__compiler" \
                --amd64.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:amd64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-arm64
__compiler="aarch64-linux-gnu-gcc"
OS::print_status info "compiling linux-arm64 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ] && [ ! "$PROJECT_OS" = "darwin" ]; then
        __target="${PROJECT_SKU}_linux-arm64"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --arm64.linux.gcc.exe:"$__compiler" \
                --arm64.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:arm64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building darwin-amd64
__compiler="clang"
OS::print_status info "compiling darwin-amd64 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ] && [ "$PROJECT_OS" = "darwin" ]; then
        __target="${PROJECT_SKU}_darwin-amd64"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:clang \
                --amd64.MacOS.clang.exe="$__compiler" \
                --amd64.MacOS.clang.linkerexe="$__compiler" \
                --passC:-fPIC \
                --cpu:amd64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building darwin-arm64
__compiler="clang"
OS::print_status info "compiling darwin-arm64 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ] && [ "$PROJECT_OS" = "darwin" ]; then
        __target="${PROJECT_SKU}_darwin-arm64"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:clang \
                --arm64.MacOS.clang.exe="$__compiler" \
                --arm64.MacOS.clang.linkerexe="$__compiler" \
                --passC:-fPIC \
                --cpu:arm64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building windows-amd64
__compiler="x86_64-w64-mingw32-gcc"
OS::print_status info "compiling windows-amd64 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_windows-amd64"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --amd64.windows.gcc.exe:"$__compiler" \
                --amd64.windows.gcc.linkerexe:"$__compiler" \
                --os:windows \
                --cpu:amd64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building windows-arm64
__compiler="x86_64-w64-mingw32-gcc"
OS::print_status info "compiling windows-arm64 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_windows-arm64"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --arm64.windows.gcc.exe:"$__compiler" \
                --arm64.windows.gcc.linkerexe:"$__compiler" \
                --os:windows \
                --cpu:arm64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-armel
__compiler="arm-linux-gnueabi-gcc"
OS::print_status info "compiling linux-armel with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-armel"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --arm.linux.gcc.exe:"$__compiler" \
                --arm.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:arm \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-armhf
__compiler="arm-linux-gnueabihf-gcc"
OS::print_status info "compiling linux-armhf with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-armhf"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --arm.linux.gcc.exe:"$__compiler" \
                --arm.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:arm \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-mips
__compiler="mips-linux-gnu-gcc"
OS::print_status info "compiling linux-mips with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-mips"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --mips.linux.gcc.exe:"$__compiler" \
                --mips.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:mips \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-mipsle
__compiler="mipsel-linux-gnu-gcc"
OS::print_status info "compiling linux-mipsle with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-mipsle"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --mipsel.linux.gcc.exe:"$__compiler" \
                --mipsel.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:mipsel \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-mips64
__compiler="mips64-linux-gnuabi64-gcc"
OS::print_status info "compiling linux-mips64 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-mips64"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --mips64.linux.gcc.exe:"$__compiler" \
                --mips64.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:mips64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-mips64le
__compiler="mips64el-linux-gnuabi64-gcc"
OS::print_status info "compiling linux-mips64le with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-mips64le"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --mips64el.linux.gcc.exe:"$__compiler" \
                --mips64el.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:mips64el \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-mips64r6
__compiler="mipsisa64r6-linux-gnuabi64-gcc"
OS::print_status info "compiling linux-mips64r6 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-mips64r6"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --mips64.linux.gcc.exe:"$__compiler" \
                --mips64.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:mips64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-mips64r6le
__compiler="mipsisa64r6el-linux-gnuabi64-gcc"
OS::print_status info "compiling linux-mips64r6le with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-mips64r6le"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --mips64el.linux.gcc.exe:"$__compiler" \
                --mips64el.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:mips64el \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-powerpc
__compiler="powerpc-linux-gnu-gcc"
OS::print_status info "compiling linux-powerpc with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-powerpc"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --powerpc.linux.gcc.exe:"$__compiler" \
                --powerpc.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:powerpc \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-ppc64le
__compiler="powerpc64le-linux-gnu-gcc"
OS::print_status info "compiling linux-ppc64le with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-ppc64le"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:gcc \
                --passC:-static --passL:-static \
                --passC:-s --passL:-s \
                --powerpc64el.linux.gcc.exe:"$__compiler" \
                --powerpc64el.linux.gcc.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:powerpc64el \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building linux-riscv64
__compiler="clang"
OS::print_status info "compiling linux-riscv64 with ${__compiler}...\n"
OS::is_command_available "$__compiler"
if [ $? -eq 0 ]; then
        __target="${PROJECT_SKU}_linux-riscv64"
        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
                --cc:clang \
                --riscv64.clang.exe:"$__compiler" \
                --riscv64.clang.linkerexe:"$__compiler" \
                --os:linux \
                --cpu:riscv64 \
                --out:"${__build}/${__target}" \
                "$__main"
        if [ $? -ne 0 ]; then
                OS::print_status error "build failed.\n"
                return 1
        fi
else
        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
fi




# building js-wasm
#__compiler="emcc"
#OS::print_status info "compiling js-wasm with ${__compiler}...\n"
#OS::is_command_available "$__compiler"
#if [ $? -eq 0 ]; then
#        __target="${PROJECT_SKU}_js-wasm.wasm"
#        nim ${SETTINGS_CC} ${SETTINGS_NIM} \
#                --cc:clang \
#                --passC:-static --passL:-static \
#                --passC:-s --passL:-s \
#                --clang.exe:"$__compiler" \
#                --clang.linkerexe:"$__compiler" \
#                --os:linux \
#                --out:"${__build}/${__target}" \
#                "$__main"
#        if [ $? -ne 0 ]; then
#                OS::print_status error "build failed.\n"
#                return 1
#        fi
#else
#        OS::print_status warning "compilation skipped. Cross-compile is unavailable.\n"
#fi




# building js-js
OS::print_status info "compiling js-js...\n"
__target="${PROJECT_SKU}_js-js.js"
nim js ${SETTINGS_NIM} --out:"${__build}/${__target}" "$__main"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# placeholding source code flag
__file="${PROJECT_SKU}-src_any-any"
OS::print_status info "building output file: ${__file}\n"
touch "${__build}/${__file}"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# placeholding homebrew flag
__file="${PROJECT_SKU}-homebrew_any-any"
OS::print_status info "building output file: ${__file}\n"
touch "${__build}/${__file}"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# placeholding chocolatey flag
__file="${PROJECT_SKU}-chocolatey_any-any"
OS::print_status info "building output file: ${__file}\n"
touch "${__build}/${__file}"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# report status
return 0
