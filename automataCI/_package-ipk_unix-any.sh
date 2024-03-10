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
. "${LIBS_AUTOMATACI}/services/io/os.sh"
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/compilers/ipk.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Run_IPK() {
        #__line="$1"


        # parse input
        __line="$1"

        _dest="${__line%%|*}"
        __line="${__line#*|}"

        _target="${__line%%|*}"
        __line="${__line#*|}"

        _target_filename="${__line%%|*}"
        __line="${__line#*|}"

        _target_os="${__line%%|*}"
        __line="${__line#*|}"

        _target_arch="${__line%%|*}"
        __line="${__line#*|}"


        # validate input
        I18N_Check_Availability "IPK"
        IPK_Is_Available "$_target_os" "$_target_arch"
        case $? in
        2|3)
                I18N_Check_Incompatible_Skipped
                return 0
                ;;
        0)
                # accepted
                ;;
        *)
                I18N_Check_Failed
                return 0
                ;;
        esac


        # prepare workspace and required values
        I18N_Create_Package "IPK"
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}.ipk"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/ipk_${_src}"
        I18N_Remake "$_src"
        FS_Remake_Directory "${_src}"
        if [ $? -ne 0 ]; then
                I18N_Remake_Failed
                return 1
        fi
        FS_Make_Directory "${_src}/control"
        FS_Make_Directory "${_src}/data"


        # execute
        I18N_Check "$_target_path"
        FS_Is_File "$_target_path"
        if [ $? -eq 0 ]; then
                I18N_Check_Failed
                return 1
        fi

        cmd="PACKAGE_Assemble_IPK_Content"
        I18N_Check_Function "$cmd"
        OS_Is_Command_Available "$cmd"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi

        I18N_Assemble_Package
        "$cmd" "$_target" "$_src" "$_target_filename" "$_target_os" "$_target_arch"
        case $? in
        10)
                I18N_Assemble_Skipped
                FS_Remove_Silently "$_src"
                return 0
                ;;
        0)
                # accepted
                ;;
        *)
                I18N_Assemble_Failed
                return 1
                ;;
        esac

        I18N_Check "control/control"
        FS_Is_File "${_src}/control/control"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi

        I18N_Package "$_target_path"
        IPK_Create_Archive "$_src" "$_target_path"
        if [ $? -ne 0 ]; then
                I18N_Package_Failed
                return 1
        fi


        # report status
        return 0
}
