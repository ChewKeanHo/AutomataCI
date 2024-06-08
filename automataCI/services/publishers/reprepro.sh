#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




REPREPRO_Create_Conf() {
        ___directory="$1"
        ___codename="$2"
        ___suite="$3"
        ___components="$4"
        ___architectures="$5"
        ___gpg="$6"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___codename") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___suite") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___components") -eq 0 ]; then
                return 1
        fi


        # execute
        ___filename="${___directory}/conf/distributions"
        FS_Make_Housing_Directory "$___filename"
        FS_Remove_Silently "$___filename"
        if [ $(STRINGS_Is_Empty "$___gpg") -eq 0 ]; then
                FS_Write_File "$___filename" "\
Codename: ${___codename}
Suite: ${___suite}
Components: ${___components}
Architectures:"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        else
                FS_Write_File "$___filename" "\
Codename: ${___codename}
Suite: ${___suite}
Components: ${___components}
SignWith: ${___gpg}
Architectures:"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        fi


        if [ $(STRINGS_Is_Empty "$___architectures") -eq 0 ]; then
                ___old_IFS="$IFS"
                while IFS= read -r ___arch || [ -n "$___arch" ]; do
                        FS_Append_File "$___filename" " $___arch"
                        while IFS= read -r ___os || [ -n "$___os" ]; do
                                FS_Append_File "$___filename" " ${___os}-${___arch}"
                        done << EOF
linux
kfreebsd
knetbsd
kopensolaris
hurd
darwin
dragonflybsd
freebsd
netbsd
openbsd
aix
solaris
EOF
                done << EOF
armhf
armel
mipsn32
mipsn32el
mipsn32r6
mipsn32r6el
mips64
mips64el
mips64r6
mips64r6el
powerpcspe
x32
arm64ilp32
alpha
amd64
arc
armeb
arm
arm64
avr32
hppa
loong64
i386
ia64
m32r
m68k
mips
mipsel
mipsr6
mipsr6el
nios2
or1k
powerpc
powerpcel
ppc64
ppc64el
riscv64
s390
s390x
sh3
sh3eb
sh4
sh4eb
sparc
sparc64
tilegx
EOF
                IFS="$___old_IFS" && unset ___line ___old_IFS
                FS_Append_File "$___filename" "\n"
        else
                FS_Append_File "$___filename" " ${___architectures}\n"
        fi


        # report status
        return 0
}




REPREPRO_Is_Available() {
        # execute
        OS_Is_Command_Available "reprepro"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




REPREPRO_Publish() {
        ___target="$1"
        ___directory="$2"
        ___datastore="$3"
        ___db_directory="$4"
        ___codename="$5"


        # validate input
        if [ $(STRINGS_Is_Empty "$___target") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___datastore") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___codename") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        FS_Make_Directory "${___db_directory}"
        FS_Make_Directory "${___directory}"
        FS_Make_Directory "${___datastore}"
        reprepro --basedir "${___datastore}" \
                --dbdir "${___db_directory}" \
                --outdir "${___directory}" \
                includedeb "${___codename}" \
                "$___target"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




REPREPRO_Setup() {
        # validate input
        OS_Is_Command_Available "brew"
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "reprepro"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        brew install reprepro
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
