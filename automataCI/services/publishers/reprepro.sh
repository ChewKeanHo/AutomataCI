#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at:
#                http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




REPREPRO::create_conf() {
        __directory="$1"
        __codename="$2"
        __suite="$3"
        __components="$4"
        __architectures="$5"
        __gpg="$6"


        # validate input
        if [ -z "$__directory" ] ||
                [ ! -d "$__directory" ] ||
                [ -z "$__codename" ] ||
                [ -z "$__suite" ] ||
                [ -z "$__components" ] ||
                [ -z "$__gpg" ]; then
                return 1
        fi

        if [ -z "$__architectures" ]; then
                __architectures="\
armhf \
armel \
mipsn32 \
mipsn32el \
mipsn32r6 \
mipsn32r6el \
mips64 \
mips64el \
mips64r6 \
mips64r6el \
powerpcspe \
x32 \
arm64ilp32 \
alpha \
amd64 \
arc \
armeb \
arm \
arm64 \
avr32 \
hppa \
loong64 \
i386 \
ia64 \
m32r \
m68k \
mips \
mipsel \
mipsr6 \
mipsr6el \
nios2 \
or1k \
powerpc \
powerpcel \
ppc64 \
ppc64el \
riscv64 \
s390 \
s390x \
sh3 \
sh3eb \
sh4 \
sh4eb \
sparc \
sparc64 \
tilegx"
        fi


        # execute
        __filename="${__directory}/conf/distributions"
        FS::make_housing_directory "$__filename"
        FS::remove_silently "$__filename"
        FS::write_file "$__filename" "\
Codename: ${__codename}
Suite: ${__suite}
Architectures: ${__architectures}
Components: ${__components}
SignWith: ${__gpg}
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




REPREPRO::is_available() {
        OS::is_command_available "reprepro"
        if [ $? -ne 0 ]; then
                return 1
        fi

        # report status
        return 0
}




REPREPRO::publish() {
        __target="$1"
        __directory="$2"
        __datastore="$3"
        __db_directory="$4"
        __codename="$5"


        # validate input
        if [ -z "$__target" ] ||
                [ -z "$__directory" ] ||
                [ -z "$__datastore" ] ||
                [ -z "$__codename" ] ||
                [ ! -d "$__directory" ] ||
                [ ! -d "$__datastore" ]; then
                return 1
        fi


        # execute
        FS::remake_directory "${__db_directory}"
        FS::remake_directory "${__directory}"
        reprepro --basedir "${__datastore}" \
                --dbdir "${__db_directory}" \
                --outdir "${__directory}" \
                includedeb "${__codename}" \
                "$__target"


        # report status
        if [ $? -eq 0 ]; then
                return 0
        fi

        return 1
}
