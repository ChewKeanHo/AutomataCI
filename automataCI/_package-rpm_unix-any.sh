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
. "${LIBS_AUTOMATACI}/services/compilers/copyright.sh"
. "${LIBS_AUTOMATACI}/services/compilers/manual.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rpm.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Run_RPM() {
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
        I18N_Check_Availability "RPM"
        RPM_Is_Available "$_target_os" "$_target_arch"
        case $? in
        2)
                I18N_Check_Incompatible_Skipped
                return 0
                ;;
        0|3)
                # accepted
                ;;
        *)
                I18N_Check_Failed_Skipped
                return 0
                ;;
        esac

        I18N_Check_Availability "MANUAL"
        MANUAL_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # prepare workspace and required values
        I18N_Create_Package "RPM"
        _src="${_target_filename}_${_target_os}-${_target_arch}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/packagers-rpm-${_src}"
        I18N_Remake "$_src"
        FS_Remake_Directory "$_src"
        if [ $? -ne 0 ]; then
                I18N_Remake_Failed
                return 1
        fi
        FS_Make_Directory "${_src}/BUILD"
        FS_Make_Directory "${_src}/SPECS"


        # copy all complimentary files to the workspace
        cmd="PACKAGE_Assemble_RPM_Content"
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


        # archive the assembled payload
        I18N_Package "$_dest"
        RPM_Create_Archive "$_src" "$_dest" "$_target_arch"
        if [ $? -ne 0 ]; then
                I18N_Package_Failed
                return 1
        fi


        # report status
        return 0
}
