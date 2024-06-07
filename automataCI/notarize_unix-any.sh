#!/bin/sh
# Copyright 2023 (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# source locally provided functions
__recipe="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/${PROJECT_PATH_CI}"
__recipe="${__recipe}/notarize_unix-any.sh"
FS_Is_File "$__recipe"
if [ $? -eq 0 ]; then
        I18N_Run "$__recipe"
        . "$__recipe"
        if [ $? -ne 0 ]; then
                I18N_Run_Failed
                return 1
        fi
fi




# begin notarize
FS_Is_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
if [ $? -ne 0 ]; then
        # nothing build - bailing
        return 0
fi

for i in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"/*; do
        FS_Is_File "$i"
        if [ $? -ne 0 ]; then
                continue
        fi


        # parse build candidate
        I18N_Detected "$i"
        TARGET_FILENAME="$(FS_Get_File "$i")"
        TARGET_FILENAME="$(FS_Extension_Remove "$TARGET_FILENAME")"
        TARGET_FILENAME="${TARGET_FILENAME%.*}"
        TARGET_OS="${TARGET_FILENAME##*_}"
        TARGET_FILENAME="${TARGET_FILENAME%%_*}"
        TARGET_ARCH="${TARGET_OS##*-}"
        TARGET_OS="${TARGET_OS%%-*}"

        if [ "$(STRINGS_Is_Empty "$TARGET_OS")" -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$TARGET_ARCH") -eq 0 ] ||
                [ $(STRINGS_Is_Empty "$TARGET_FILENAME") -eq 0 ]; then
                I18N_File_Has_Bad_Stat_Skipped
                continue
        fi

        STRINGS_Has_Prefix "$PROJECT_SKU" "$TARGET_FILENAME"
        if [ $? -ne 0 ]; then
                I18N_Is_Incompatible_Skipped "$TARGET_FILENAME"
                continue
        fi


        # execute
        cmd="NOTARIZE_Certify"
        I18N_Check_Availability "$cmd"
        OS_Is_Command_Available "$cmd"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                continue
        fi

        "$cmd" "$i" \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}" \
                "$TARGET_FILENAME" \
                "$TARGET_OS" \
                "$TARGET_ARCH"
        case $? in
        12)
                I18N_Simulate_Notarize
                ;;
        11)
                I18N_Notarize_Unavailable
                ;;
        10)
                I18N_Notarize_Not_Applicable
                ;;
        0)
                I18N_Run_Successful
                ;;
        *)
                I18N_Notarize_Failed
                return 1
                ;;
        esac
done




# report status
return 0
