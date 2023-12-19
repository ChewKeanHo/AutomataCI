#!/bin/sh
# Copyright 2023  (Holloway) Chew, Kean Ho <hollowaykeanho@gmail.com>
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
. "${LIBS_AUTOMATACI}/services/compilers/copyright.sh"
. "${LIBS_AUTOMATACI}/services/compilers/manual.sh"
. "${LIBS_AUTOMATACI}/services/compilers/rpm.sh"

. "${LIBS_AUTOMATACI}/services/i18n/status-job-package.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-run.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




PACKAGE::run_rpm() {
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
        I18N_Status_Print_Check_Availability "RPM"
        RPM::is_available "$_target_os" "$_target_arch"
        case $? in
        2|3)
                I18N_Status_Print_Check_Availability_Incompatible "RPM"
                return 0
                ;;
        0)
                # accepted
                ;;
        *)
                I18N_Status_Print_Check_Availability_Failed "RPM"
                return 0
                ;;
        esac

        I18N_Status_Print_Check_Availability "MANUAL DOCS"
        MANUAL_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Check_Availability_Failed "MANUAL DOCS"
                return 1
        fi


        # prepare workspace and required values
        I18N_Status_Print_Package_Create "RPM"
        _src="${_target_filename}_${_target_os}-${_target_arch}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/rpm_${_src}"
        I18N_Status_Print_Package_Workspace_Remake "$_src"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Remake_Failed
                return 1
        fi
        FS::make_directory "${_src}/BUILD"
        FS::make_directory "${_src}/SPECS"


        # copy all complimentary files to the workspace
        cmd="PACKAGE::assemble_rpm_content"
        I18N_Status_Print_Package_Assembler_Check "$cmd"
        OS::is_command_available "$cmd"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Check_Failed
                return 1
        fi

        I18N_Status_Print_Package_Assembler_Exec
        "$cmd" "$_target" "$_src" "$_target_filename" "$_target_os" "$_target_arch"
        case $? in
        10)
                I18N_Status_Print_Package_Assembler_Exec_Skipped
                FS::remove_silently "$_src"
                return 0
                ;;
        0)
                # accepted
                ;;
        *)
                I18N_Status_Print_Package_Assembler_Exec_Failed
                return 1
                ;;
        esac


        # archive the assembled payload
        I18N_Status_Print_Package_Exec "$_dest"
        RPM::create_archive "$_src" "$_dest" "$_target_arch"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Exec_Failed "$_dest"
                return 1
        fi


        # report status
        return 0
}
