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




FLATPAK_Create_Archive() {
        ___directory="$1"
        ___destination="$2"
        ___repo="$3"
        ___app_id="$4"
        ___gpg_id="$5"


        # validate input
        if [ $(STRINGS_Is_Empty "$___directory") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___destination") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___repo") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___app_id") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___gpg_id") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___directory"
        if [ $? -ne 0 ]; then
                return 1
        fi

        ___path_build="./build"
        ___path_export="./export"
        ___path_package="./out.flatpak"
        ___path_manifest="./manifest.yml"
        FS_Make_Directory "$___repo"


        # change location into the workspace
        ___current_path="$PWD"
        cd "$___directory"


        # build archive
        FS_Is_File "$___path_manifest"
        if [ $? -ne 0 ]; then
                return 1
        fi

        flatpak-builder \
                --user \
                --force-clean \
                --repo="$___repo" \
                --gpg-sign="$___gpg_id" \
                "$___path_build" \
                "$___path_manifest"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        flatpak build-export "$___path_export" "$___path_build"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        flatpak build-bundle "$___path_export" "$___path_package" "$___app_id"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi


        # export output
        FS_Is_File "$___path_package"
        if [ $? -ne 0 ]; then
                cd "$___current_path" && unset ___current_path
                return 1
        fi

        FS_Move "$___path_package" "$___destination"
        ___process=$?


        # head back to current directory
        cd "${___current_path}" && unset ___current_path


        # report status
        if [ $___process -ne 0 ]; then
                return 1
        fi

        return 0
}




FLATPAK_Is_Available() {
        ___os="$1"
        ___arch="$2"


        # validate input
        if [ $(STRINGS_Is_Empty "$___os") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___arch") -eq 0 ]; then
                return 1
        fi


        # check compatible target os
        case "$___os" in
        linux|any)
                # accepted
                ;;
        *)
                return 2
                ;;
        esac


        # check compatible target cpu architecture
        case "$___arch" in
        any)
                return 3
                ;;
        *)
                ;;
        esac


        # validate dependencies
        OS_Is_Command_Available "flatpak-builder"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
