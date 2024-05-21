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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/io/disk.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/archive/ar.sh"
. "${LIBS_AUTOMATACI}/services/crypto/gpg.sh"
. "${LIBS_AUTOMATACI}/services/checksum/md5.sh"




DEB_Create_Archive() {
        ___directory="$1"
        ___destination="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "${___directory}/control"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "${___directory}/data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___directory}/control/control"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # capture current directory
        ___current_path="$PWD"


        # package control
        cd "${___directory}/control"
        TAR_Create_XZ "../control.tar.xz" "*"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # package data
        cd "${___directory}/data"
        TAR_Create_XZ "../data.tar.xz" "*"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # generate debian-binary
        cd "${___directory}"
        FS_Write_File "${___directory}/debian-binary" "2.0\n"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # archive into deb
        ___file="package.deb"
        AR_Create "$___file" "debian-binary control.tar.xz data.tar.xz"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # move to destination
        FS_Remove_Silently "$___destination"
        FS_Move "$___file" "$___destination"
        ___process=$?


        # return to current directory
        cd "$___current_path" && unset ___current_path


        # report status
        if [ $___process -ne 0 ]; then
                return 1
        fi

        return 0
}




DEB_Create_Changelog() {
        ___location="$1"
        ___filepath="$2"
        ___sku="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$___location") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___filepath") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$___filepath"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # create housing directory path
        FS_Make_Housing_Directory "$___location"
        FS_Remove_Silently "$___location"


        # copy processed file to target location
        FS_Copy_File "$___filepath" "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DEB_Create_Checksum() {
        #___directory="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # prepare workspace
        ___location="${1}/control/md5sums"
        FS_Remove_Silently "$___location"
        FS_Make_Housing_Directory "$___location"


        # checksum every items
        for ___line in $(find "${1}/data" -type f); do
                ___checksum="$(MD5_Checksum_From_File "$___line")"
                FS_Append_File "$___location" \
                        "${___checksum%% *} ${___line##*${1}/data/}\n"
                if [ $? -ne 0 ]; then
                        return 1
                fi
        done


        # report status
        return 0
}




DEB_Create_Control() {
        ___directory="$1"
        ___resources="$2"
        ___sku="$3"
        ___version="$4"
        ___arch="$5"
        ___os="$6"
        ___name="$7"
        ___email="$8"
        ___website="$9"
        ___pitch="${10}"
        ___priority="${11}"
        ___section="${12}"
        ___description_filepath="${13}"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___resources") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___version") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___email") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___pitch") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___priority") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___section") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___resources"
        if [ $? -ne 0 ]; then
                return 1
        fi

        case "$___priority" in
        required|important|standard|optional|extra)
                ;;
        *)
                return 1
                ;;
        esac


        # prepare workspace
        ___arch="$(DEB_Get_Architecture "$___os" "$___arch")"
        ___location="${___directory}/control/control"
        FS_Make_Housing_Directory "${___location}"
        FS_Remove_Silently "${___location}"


        # generate control file
        ___size="$(DISK_Calculate_Size "${___directory}/data")"
        if [ $(STRINGS_Is_Empty "$___size") -eq 0 ]; then
                return 1
        fi

        FS_Write_File "$___location" "\
Package: $___sku
Version: $___version
Architecture: $___arch
Maintainer: $___name <$___email>
Installed-Size: $___size
Section: $___section
Priority: $___priority
Homepage: $___website
Description: $___pitch
"


        # append description data file
        if [ ! "$(FS_Is_File "$___description_filepath")" = "0" ]; then
                return 0 # report status early
        fi

         ___old_IFS="$IFS"
        while IFS="" read -r ___line || [ -n "$___line" ]; do
                if [ $(STRINGS_Is_Empty "$___line") -ne 0 ] &&
                        [ $(STRINGS_Is_Empty "${___line%%#*}") -eq 0 ]; then
                        continue
                fi

                if [ $(STRINGS_Is_Empty "${___line}") -eq 0 ]; then
                        ___line=" ."
                else
                        ___line=" ${___line}"
                fi

                FS_Append_File "$___location" "${___line}\n"
        done < "${___description_filepath}"
        IFS="$___old_IFS" && unset ___old_IFS ___line


        # report status
        return 0
}




DEB_Create_Source_List() {
        ___directory="$1"
        ___gpg_id="$2"
        ___url="$3"
        ___codename="$4"
        ___distribution="$5"
        ___keyring="$6"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___url") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___codename") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___distribution") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___keyring") -eq 0 ]; then
                return 1
        fi

        if [ $(STRINGS_Is_Empty "$___gpg_id") -eq 0 ] && [ $(OS_Is_Run_Simulated) -ne 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        ___url="${___url}/deb"
        ___url="${___url%//deb*}/deb"
        ___key="usr/local/share/keyrings/${___keyring}-keyring.gpg"
        ___filename="${___directory}/data/etc/apt/sources.list.d/${___keyring}.list"

        FS_Is_File "$___filename"
        if [ $? -eq 0 ]; then
                return 10
        fi

        FS_Is_File "${___directory}/data/${___key}"
        if [ $? -eq 0 ]; then
                return 1
        fi


        FS_Make_Housing_Directory "$___filename"
        FS_Write_File "$___filename" "\
# WARNING: AUTO-GENERATED - DO NOT EDIT!
deb [signed-by=/${___key}] ${___url} ${___codename} ${___distribution}
"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Make_Housing_Directory "${___directory}/data/${___key}"
        if [ $(OS_Is_Run_Simulated) -eq 0 ]; then
                FS_Write_File "${___directory}/data/${___key}" ""
        else
                GPG_Export_Public_Keyring "${___directory}/data/${___key}" "$___gpg_id"
        fi
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




DEB_Get_Architecture() {
        #___os="$1"
        #___arch="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                printf -- ""
                return 1
        fi


        # process os
        case "$1" in
        linux)
                ___output=""
                ;;
        dragonfly)
                ___output="dragonflybsd-"
                ;;
        *)
                ___output="${1}-"
                ;;
        esac


        # process arch
        case "$2" in
        386|i386|486|i486|586|i586|686|i686)
                ___output="${___output}i386"
                ;;
        mipsle)
                ___output="${___output}mipsel"
                ;;
        mipsr6le)
                ___output="${___output}mipsr6el"
                ;;
        mips32le)
                ___output="${___output}mips32el"
                ;;
        mips32r6le)
                ___output="${___output}mips32r6el"
                ;;
        mips64le)
                ___output="${___output}mips64el"
                ;;
        mips64r6le)
                ___output="${___output}mips64r6el"
                ;;
        powerpcle)
                ___output="${___output}powerpcel"
                ;;
        ppc64le)
                ___output="${___output}ppc64el"
                ;;
        *)
                ___output="${___output}${2}"
                ;;
        esac


        # report status
        ___output="$(STRINGS_To_Lowercase "$___output")"
        printf -- "%b" "$___output"
        return 0
}




DEB_Is_Available() {
        #___os="$1"
        #___arch="$2"

        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                return 1
        fi


        # validate dependencies
        MD5_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        TAR_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        AR_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        DISK_Is_Available
        if [ $? -ne 0 ]; then
                return 1
        fi

        OS_Is_Command_Available "find"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # check compatible target os
        case "$1" in
        windows|darwin)
                return 2
                ;;
        *)
                # accepted
                ;;
        esac



        # check compatible target cpu architecture
        case "$2" in
        any)
                return 3
                ;;
        *)
                # accepted
                ;;
        esac


        # report status
        return 0
}




DEB_Is_Valid() {
        #___target="$1"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # execute
        if [ "${1##*.}" = "deb" ]; then
                return 0
        fi


        # return status
        return 1
}
