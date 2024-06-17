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
. "${LIBS_AUTOMATACI}/services/compilers/rust.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Run_CARGO() {
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
        if [ $(STRINGS_Is_Empty "$PROJECT_RUST") -eq 0 ]; then
                return 0
        fi

        I18N_Check_Availability "RUST"
        RUST_Activate_Local_Environment
        RUST_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 0
        fi


        # prepare workspace and required values
        I18N_Create_Package "RUST"
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/cargo_${_src}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/packagers-cargo-${_src}"
        I18N_Remake "$_src"
        FS_Remake_Directory "$_src"
        if [ $? -ne 0 ]; then
                I18N_Remake_Failed
                return 1
        fi

        I18N_Check "$_target_path"
        FS_Is_Directory "$_target_path"
        if [ $? -eq 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # copy all complimentary files to the workspace
        cmd="PACKAGE_Assemble_CARGO_Content"
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
                ;;
        *)
                I18N_Assemble_Failed
                return 1
                ;;
        esac


        # archive the assembled payload
        I18N_Package "$_target_path"
        FS_Make_Directory "$_target_path"
        RUST_Create_Archive "$_src" "$_target_path"
        if [ $? -ne 0 ]; then
                I18N_Package_Failed
                return 1
        fi


        # report status
        return 0
}
