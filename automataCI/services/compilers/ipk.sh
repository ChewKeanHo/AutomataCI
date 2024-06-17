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
. "${LIBS_AUTOMATACI}/services/io/disk.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/compilers/deb.sh"




IPK_Create_Archive() {
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
        TAR_Create_GZ "${___directory}/control.tar.gz" "."
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # package data
        cd "${___directory}/data"
        TAR_Create_GZ "${___directory}/data.tar.gz" "."
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


        # archive into ipk
        ___file="package.ipk"
        TAR_Create_GZ "$___file" "debian-binary control.tar.gz data.tar.gz"
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




IPK_Create_Control() {
        #___directory="$1"
        #___resources="$2"
        #___sku="$3"
        #___version="$4"
        #___arch="$5"
        #___os="$6"
        #___name="$7"
        #___email="$8"
        #___website="$9"
        #___pitch="${10}"
        #___priority="${11}"
        #___section="${12}"
        #___description_filepath="${13}"


        # execute
        DEB_Create_Control "$1" \
                "$2" \
                "$3" \
                "$4" \
                "$5" \
                "$6" \
                "$7" \
                "$8" \
                "$9" \
                "${10}" \
                "${11}" \
                "${12}" \
                "${13}"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




IPK_Get_Architecture() {
        #___os="$1"
        #___arch="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] || [ $(STRINGS_Is_Empty "$2") -eq 0 ]; then
                printf -- ""
                return 1
        fi


        # report status
        printf -- "%b" "$(STRINGS_To_Lowercase "${1}-${2}")"
        return 0
}




IPK_Is_Available() {
        ___os="$1"
        ___arch="$2"

        if [ $(STRINGS_Is_Empty "$___os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arch") -eq 0 ]; then
                return 1
        fi


        # validate dependencies
        TAR_Is_Available
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


        # check compatible target cpu architecture
        case "$___arch" in
        any)
                return 3
                ;;
        *)
                ;;
        esac


        # report status
        return 0
}




IPK_Is_Valid() {
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
        if [ "${1##*.}" = "ipk" ]; then
                return 0
        fi


        # return status
        return 1
}
