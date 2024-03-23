#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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




APPIMAGE_Is_Available() {
        # validate input
        case "$(OS_Get)" in
        darwin)
                return 0 # not applicable - requires linux kernel libfuse2
                ;;
        windows)
                return 0 # not applicable - requires linux kernel libfuse2
                ;;
        *)
                # Other UNIX systems (e.g. Linux)
                ;;
        esac


        # execute
        OS_Is_Command_Available "fusermount"
        if [ $? -eq 0 ]; then
                fusermount -V &> /dev/null
                if [ $? -eq 0 ]; then
                        return 0
                fi
        fi


        # report status
        return 1
}




APPIMAGE_Setup() {
        # validate input
        APPIMAGE_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi


        # execute
        ## TODO: setup APPIMAGE packager


        # report status
        return 0
}




APPIMAGE_Unpack() {
        #___dest="$1"
        #___dir_install="$2"
        #___image="$3"


        # validate input
        if [ $(STRINGS_Is_Empty "$1") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$2") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$3") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_PATH_TEMP") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$PROJECT_PATH_ROOT") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$1"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$2"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_File "$3"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # setup a temporary directory
        ___mnt="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/mnt-appimage-$(FS_Get_File "$1")"
        FS_Remake_Directory "$___mnt"
        su root --preserve-environment --command "mount -o loop '$3' '$___mnt'"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_All "${___mnt}/" "$2"
        if [ $? -ne 0 ]; then
                return 1
        fi

        su root --preserve-environment --command "umount '$___mnt'"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Remove_Silently "$___mnt"


        # symlink to dest
        ln -s "${2}/AppRun" "$1"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
