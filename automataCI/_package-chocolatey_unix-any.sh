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
. "${LIBS_AUTOMATACI}/services/publishers/chocolatey.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Run_CHOCOLATEY() {
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
        I18N_Check_Availability "ZIP"
        ZIP_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # prepare workspace and required values
        I18N_Create_Package "CHOCOLATEY"
        _src="${_target_filename}_${PROJECT_VERSION}_${_target_os}-${_target_arch}"
        _target_path="${_dest}/${_src}"
        _src="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/packagers-choco-${_src}"
        I18N_Remake "$_src"
        FS_Remake_Directory "$_src"
        if [ $? -ne 0 ]; then
                I18N_Remake_Failed
                return 1
        fi


        # copy all complimentary files to the workspace
        cmd="PACKAGE_Assemble_CHOCOLATEY_Content"
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


        # check nuspec file is available
        I18N_Check ".nuspec"
        __name=""
        for __file in "${_src}/"*.nuspec; do
                FS_Is_File "${__file}"
                if [ $? -eq 0 ]; then
                        if [ $(STRINGS_Is_Empty "$__name") -ne 0 ]; then
                                I18N_Check_Failed
                                return 1
                        fi

                        __name="${__file##*/}"
                        __name="${__name%.nuspec*}"
                fi
        done

        if [ $(STRINGS_Is_Empty "$__name") -eq 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # archive the assembled payload
        __name="${__name}-chocolatey_${PROJECT_VERSION}_${_target_os}-${_target_arch}.nupkg"
        __name="${_dest}/${__name}"
        I18N_Archive "$__name"
        CHOCOLATEY_Archive "$__name" "$_src"
        if [ $? -ne 0 ]; then
                I18N_Archive_Failed
                return 1
        fi


        # test the package
        I18N_Test "$__name"
        CHOCOLATEY_Is_Available
        if [ $? -eq 0 ]; then
                CHOCOLATEY_Test "$__name"
                if [ $? -ne 0 ]; then
                        I18N_Test_Failed
                        return 1
                fi
        else
                I18N_Test_Skipped
        fi


        # report status
        return 0
}
