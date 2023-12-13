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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/checksum/shasum.sh"

. "${LIBS_AUTOMATACI}/services/i18n/status-file.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-job-package.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-run.sh"
. "${LIBS_AUTOMATACI}/services/i18n/status-shasum.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from ci.cmd instead!\n"
        return 1
fi




PACKAGE::run_homebrew() {
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
        I18N_Status_Print_Check_Availability "TAR"
        TAR_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Check_Availability_Incompatible "TAR"
                return 1
        fi


        # prepare workspace and required values
        I18N_Status_Print_Package_Create "HOMEBREW"
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/homebrew_${_src}"
        I18N_Status_Print_Package_Workspace_Remake "$_src"
        FS::remake_directory "$_src"
        if [ $? -ne 0 ]; then
                I18N_Status_Print_Package_Remake_Failed
                return 1
        fi


        # check formula.rb is available
        I18N_Status_Print_File_Check_Exists "formula.rb"
        FS::is_file "${_src}/formula.rb"
        if [ $? -eq 0 ]; then
                I18N_Status_Print_File_Check_Failed
                return 1
        fi


        # copy all complimentary files to the workspace
        cmd="PACKAGE::assemble_homebrew_content"
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
        __current_path="$PWD" && cd "$_src"
        I18N_Status_Print_File_Archive "${_target_path}.tar.xz"
        TAR_Create_XZ "${_target_path}.tar.xz" "*"
        __exit=$?
        cd "$__current_path" && unset __current_path
        if [ $__exit -ne 0 ]; then
                I18N_Status_Print_File_Archive_Failed
                return 1
        fi


        # sha256 the package
        I18N_Status_Print_Shasum "SHA256"
        __shasum="$(SHASUM::create_file "${_target_path}.tar.xz" "256")"
        if [ $(STRINGS_Is_Empty "$__shasum") -eq 0 ]; then
                I18N_Status_Print_Shasum_Failed
                return 1
        fi


        # update the formula.rb script
        I18N_Status_Print_File_Update "formula.rb"
        FS::remove_silently "${_target_path}.rb"
        old_IFS="$IFS"
        while IFS="" read -r __line || [ -n "$__line" ]; do
                __line="$(STRINGS::replace_all \
                        "$__line" \
                        "{{ TARGET_PACKAGE }}" \
                        "${_target_path##*/}.tar.xz" \
                )"

                __line="$(STRINGS::replace_all \
                        "$__line" \
                        "{{ TARGET_SHASUM }}" \
                        "${__shasum}" \
                )"

                FS::append_file "${_target_path}.rb" "${__line}\n"
                if [ $? -ne 0 ]; then
                        IFS="$old_IFS" && unset __line old_IFS
                        I18N_Status_Print_File_Update_Failed
                        return 1
                fi
        done < "${_src}/formula.rb"
        IFS="$old_IFS" && unset line old_IFS


        # report status
        return 0
}
