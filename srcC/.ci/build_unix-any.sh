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
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/operators_unix-any.sh"




# safety check control surfaces
OS::print_status info "checking BUILD::compile function availability...\n"
OS::is_command_available "BUILD::compile"
if [ $? -ne 0 ]; then
        OS::print_status error "check failed.\n"
        return 1
fi

FS_Make_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"

SETTINGS_BIN="\
-Wall \
-Wextra \
-std=gnu89 \
-pedantic \
-Wstrict-prototypes \
-Wold-style-definition \
-Wundef \
-Wno-trigraphs \
-fno-strict-aliasing \
-fno-common \
-fshort-wchar \
-fstack-protector-all \
-Werror-implicit-function-declaration \
-Wno-format-security \
-Os \
-g0 \
-static \
"

COMPILER=""

EXIT_CODE=0




# execute
# compile for linux-amd64 (microprocessor)
if [ ! "$PROJECT_OS" = "darwin" ]; then
        BUILD::compile "c-binary" "linux" "amd64" "automataCI.txt" "$SETTINGS_BIN" "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi

        BUILD::compile \
                "c-library" \
                "linux" \
                "amd64" \
                "libs/sample/automataCI.txt" \
                "${SETTINGS_BIN} -pie -fPIE" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi
fi


# compile for linux-arm64 (microprocessor)
if [ ! "$PROJECT_OS" = "darwin" ]; then
        BUILD::compile "c-binary" "linux" "arm64" "automataCI.txt" "$SETTINGS_BIN" "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi

        BUILD::compile \
                "c-library" \
                "linux" \
                "arm64" \
                "libs/sample/automataCI.txt" \
                "${SETTINGS_BIN} -pie -fPIE" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi
fi


# compile for windows-amd64 (microprocessor)
BUILD::compile "c-binary" "windows" "amd64" "automataCI.txt" "$SETTINGS_BIN" "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi

BUILD::compile \
        "c-library" \
        "windows" \
        "amd64" \
        "libs/sample/automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for windows-arm64 (microprocessor)
BUILD::compile "c-binary" "windows" "arm64" "automataCI.txt" "$SETTINGS_BIN" "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi

BUILD::compile \
        "c-library" \
        "windows" \
        "arm64" \
        "libs/sample/automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for darwin-amd64 (microprocessor)
if [ "$PROJECT_OS" = "darwin" ]; then
        BUILD::compile \
                "c-binary" \
                "darwin" \
                "amd64" \
                "automataCI.txt" \
                "${SETTINGS_BIN} -target x86_64-apple-darwin-gcc" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi

        BUILD::compile \
                "c-library" \
                "darwin" \
                "amd64" \
                "libs/sample/automataCI.txt" \
                "${SETTINGS_BIN} -target x86_64-apple-darwin-gcc -fPIC" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi
fi


# compile for darwin-arm64 (microprocessor)
if [ "$PROJECT_OS" = "darwin" ]; then
        BUILD::compile \
                "c-binary" \
                "darwin" \
                "arm64" \
                "automataCI.txt" \
                "$SETTINGS_BIN -target aarch64-apple-darwin-gcc" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi

        BUILD::compile \
                "c-library" \
                "darwin" \
                "arm64" \
                "libs/sample/automataCI.txt" \
                "${SETTINGS_BIN} -target x86_64-apple-darwin-gcc -fPIC" \
                "$COMPILER"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi
fi


# compile for linux-armel (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "armel" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-armhf (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "armhf" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-mips (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "mips" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-mips64 (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "mips64" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-mips64el (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "mips64el" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-mips64r6 (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "mips64r6" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-mips64r6el (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "mips64r6el" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-powerpc (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "powerpc" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-ppc64el (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "ppc64el" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-s390x (microprocessor)
BUILD::compile \
        "c-binary" \
        "linux" \
        "s390x" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -pie -fPIE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi


# compile for linux-avr (ATMEL microcontroller)
OS::is_command_available "avr-objcopy"
if [ $? -eq 0 ]; then
        BUILD::compile "c-binary" "linux" "avr" "automataCI.txt" "\
-Wall \
-Wextra \
-std=gnu89 \
-pedantic \
-Wstrict-prototypes \
-Wold-style-definition \
-Wundef \
-Wno-trigraphs \
-fno-strict-aliasing \
-fno-common \
-fshort-wchar \
-ffunction-sections \
-fdata-sections \
-Werror-implicit-function-declaration \
-Wno-format-security \
-Os \
-g0 \
-static \
" "avr-gcc"
        if [ $? -ne 0 -a $? -ne 10 ]; then
                EXIT_CODE=1
        fi

        TARGET="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${PROJECT_SKU}_linux-avr.elf"
        if [ -f "$TARGET" ]; then
                avr-objcopy -O ihex \
                                -R .eeprom \
                                "$TARGET" \
                                "${TARGET%/*}/${PROJECT_SKU}_linux-avr.hex"
                if [ $? -ne 0 ]; then
                        EXIT_CODE=1
                fi

                FS_Remove_Silently "$TARGET"
        fi
fi


# compile for js-wasm (web)
ALLOW_MEMORY_GROWTH=1 BUILD::compile \
        "c-binary" \
        "js" \
        "wasm" \
        "automataCI.txt" \
        "${SETTINGS_BIN} -fno-stack-protector -U_FORTIFY_SOURCE" \
        "$COMPILER"
if [ $? -ne 0 -a $? -ne 10 ]; then
        EXIT_CODE=1
fi




# placeholding source code flag
__file="${PROJECT_SKU}-src_any-any"
OS::print_status info "building output file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# placeholding homebrew flag
__file="${PROJECT_SKU}-homebrew_any-any"
OS::print_status info "building output file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# placeholding chocolatey flag
__file="${PROJECT_SKU}-chocolatey_any-any"
OS::print_status info "building output file: ${__file}\n"
touch "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}/${__file}"
if [ $? -ne 0 ]; then
        OS::print_status error "build failed.\n"
        return 1
fi




# report status
return $EXIT_CODE
