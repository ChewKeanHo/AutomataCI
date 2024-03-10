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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/checksum/shasum.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Run_HOMEBREW() {
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
        I18N_Check_Availability "TAR"
        TAR_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # prepare workspace and required values
        I18N_Create_Package "HOMEBREW"
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/homebrew_${_src}"
        I18N_Remake "$_src"
        FS_Remake_Directory "$_src"
        if [ $? -ne 0 ]; then
                I18N_Remake_Failed
                return 1
        fi


        # check formula.rb is available
        I18N_Check "formula.rb"
        FS_Is_File "${_src}/formula.rb"
        if [ $? -eq 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # copy all complimentary files to the workspace
        cmd="PACKAGE_Assemble_HOMEBREW_Content"
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
        __current_path="$PWD" && cd "$_src"
        I18N_Archive "${_target_path}.tar.xz"
        TAR_Create_XZ "${_target_path}.tar.xz" "*"
        ___process=$?
        cd "$__current_path" && unset __current_path
        if [ $___process -ne 0 ]; then
                I18N_Archive_Failed
                return 1
        fi


        # sha256 the package
        I18N_Shasum "SHA256"
        __shasum="$(SHASUM_Create_From_File "${_target_path}.tar.xz" "256")"
        if [ $(STRINGS_Is_Empty "$__shasum") -eq 0 ]; then
                I18N_Shasum_Failed
                return 1
        fi


        # update the formula.rb script
        I18N_Subject_Update "formula.rb"
        FS_Remove_Silently "${_target_path}.rb"
        __old_IFS="$IFS"
        while IFS= read -r __line || [ -n "$__line" ]; do
                __line="$(STRINGS_Replace_All \
                        "$__line" \
                        "{{ TARGET_PACKAGE }}" \
                        "${_target_path##*/}.tar.xz" \
                )"

                __line="$(STRINGS_Replace_All \
                        "$__line" \
                        "{{ TARGET_SHASUM }}" \
                        "${__shasum}" \
                )"

                FS_Append_File "${_target_path}.rb" "${__line}\n"
                if [ $? -ne 0 ]; then
                        IFS="$__old_IFS" && unset __line __old_IFS
                        I18N_Update_Failed
                        return 1
                fi
        done < "${_src}/formula.rb"
        IFS="$__old_IFS" && unset __line __old_IFS


        # report status
        return 0
}
