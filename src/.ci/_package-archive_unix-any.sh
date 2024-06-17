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
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




PACKAGE_Assemble_ARCHIVE_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # package based on target's nature
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                __source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
                __dest="${_directory}/docs"

                FS_Is_Directory "$__source"
                if [ $? -ne 0 ]; then
                        return 10 # not applicable
                fi

                I18N_Assemble "$__source" "$__dest"
                FS_Make_Directory "$__dest"
                FS_Copy_All "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                return 10 # handled by lib packager
        elif [ $(FS_Is_Target_A_WASM_JS "$_target") -eq 0 ]; then
                return 10 # handled by wasm instead
        elif [ $(FS_Is_Target_A_WASM "$_target") -eq 0 ]; then
                __dest="${_directory}/assets/$(FS_Get_File "$_target")"

                I18N_Assemble "$_target" "$__dest"
                FS_Make_Housing_Directory "$__dest"
                FS_Copy_File "$_target" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi

                __source="$(FS_Extension_Remove "$_target" ".wasm").js"
                FS_Is_File "$__source"
                if [ $? -eq 0 ]; then
                        __dest="${__dest}/$(FS_Get_File "$__source")"
                        I18N_Assemble "$__source" "$__dest"
                        FS_Copy_File "$__source" "$__dest"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                fi
        elif [ $(FS_Is_Target_A_Chocolatey "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Cargo "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_MSI "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_PDF "$_target") -eq 0 ]; then
                return 10 # not applicable
        else
                __dest="${_directory}/bin/${PROJECT_SKU}"
                if [ "$_target_os" = "windows" ]; then
                        __dest="${__dest}.exe"
                fi

                I18N_Assemble "$_target" "$__dest"
                FS_Make_Housing_Directory "$__dest"
                FS_Copy_File "$_target" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi
        fi


        # copy user guide
        for __source in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/USER-GUIDES"*.pdf; do
                FS_Is_Target_Exist "$__source"
                if [ $? -ne 0 ]; then
                        continue
                fi

                __dest="${_directory}/$(FS_Get_File "$__source")"
                I18N_Assemble "$__source" "$__dest"
                FS_Copy_File "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi
        done


        # copy license file
        for __source in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/licenses/LICENSE"*.pdf; do
                FS_Is_Target_Exist "$__source"
                if [ $? -ne 0 ]; then
                        continue
                fi

                __dest="${_directory}/$(FS_Get_File "$__source")"
                I18N_Assemble "$__source" "$__dest"
                FS_Copy_File "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi
        done


        # report status
        return 0
}
