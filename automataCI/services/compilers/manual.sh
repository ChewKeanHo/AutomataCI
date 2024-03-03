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
. "${LIBS_AUTOMATACI}/services/compress/gz.sh"




MANUAL_Create() {
        ___location="$1"
        ___sku="$2"
        ___name="$3"
        ___email="$4"
        ___website="$5"


        # validate input
        if [ $(STRINGS_Is_Empty "$___location") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___sku") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___name") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___email") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$___website") -eq 0 ]; then
                return 1
        fi

        FS_Is_Directory "$___location"
        if [ $? -eq 0 ]; then
                return 1
        fi


        # prepare workspace
        FS_Make_Housing_Directory "$___location"
        FS_Remove_Silently "$___location"
        FS_Remove_Silently "${___location}.gz"


        # create basic level 1 man page that instruct users to seek --help
        FS_Write_File "${___location}" "\
.\" ${___sku} - Lv1 Manpage
.TH man 1 \"${___sku} man page\"

.SH NAME
${___sku} - Getting help

.SH SYNOPSIS
command: $ ./${___sku} help

.SH DESCRIPTION
This is a backward-compatible auto-generated system-level manual page. To make
sure you get the required and proper assistances from the software, please make
sure you call the command above.

.SH SEE ALSO
Please visit ${___website} for more info.

.SH AUTHORS
Contact: ${___name} <${___email}>
"
        if [ $? -ne 0 ]; then
                return 0
        fi


        # gunzip the manual
        GZ_Create "$___location"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}




MANUAL_Is_Available() {
        # execute
        GZ_Is_Available
        if [ $? -eq 0 ]; then
                return 0
        fi


        # report status
        return 1
}
