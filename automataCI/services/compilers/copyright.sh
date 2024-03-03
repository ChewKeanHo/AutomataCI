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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"




COPYRIGHT_Create() {
        ___location="$1"
        ___manual_file="$2"
        ___sku="$3"
        ___name="$4"
        ___email="$5"
        ___website="$6"


        # validate input
        if [ $(STRINGS_Is_Empty "$___location") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___manual_file") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___email") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "${___location}"
        if [ $? -eq 0 ]; then
                return 1
        fi

        FS_Is_File "${___manual_file}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Is_File "${___location}"
        if [ $? -eq 0 ]; then
                return 0
        fi


        # create housing directory path
        FS_Make_Housing_Directory "$___location"


        # create copyright stanza header
        FS_Write_File "$___location" "\
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${___sku}
Upstream-Contact: ${___name} <${___email}>
Source: ${___website}

"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # append manually facilitated copyright contents
        ___old_IFS="$IFS"
        while IFS= read -r ___line || [ -n "$___line" ]; do
                FS_Append_File "$___location" "$___line\n"
        done < "$___manual_file"
        IFS="$___old_IFS" && unset ___old_IFS ___line


        # report status
        return 0
}
