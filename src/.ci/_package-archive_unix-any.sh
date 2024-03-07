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
                FS_Is_Directory "${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}"
                if [ $? -ne 0 ]; then
                        return 10 # not applicable
                fi

                __source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_DOCS}/"
                I18N_Copy "${__source}/*" "$_directory"
                FS_Copy_All "$__source" "$_directory"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                I18N_Copy "$_target" "$_directory"
                FS_Copy_File "$_target" "$_directory"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        elif [ $(FS_Is_Target_A_WASM_JS "$_target") -eq 0 ]; then
                return 10 # handled by wasm instead
        elif [ $(FS_Is_Target_A_WASM "$_target") -eq 0 ]; then
                I18N_Copy "$_target" "$_directory"
                FS_Copy_File "$_target" "$_directory"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi

                __source="${_target%.wasm*}.js"
                FS_Is_File "$__source"
                if [ $? -eq 0 ]; then
                        I18N_Copy "$__source" "$_directory"
                        FS_Copy_File "$__source" "$_directory"
                        if [ $? -ne 0 ]; then
                                I18N_Copy_Failed
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
        else
                case "$_target_os" in
                windows)
                        _dest="${_directory}/${PROJECT_SKU}.exe"
                        ;;
                *)
                        _dest="${_directory}/${PROJECT_SKU}"
                        ;;
                esac

                I18N_Copy "$_target" "$_dest"
                FS_Copy_File "$_target" "$_dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        fi


        # copy user guide
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/docs/USER-GUIDES-EN.pdf"
        I18N_Copy "$_target" "$_directory"
        FS_Copy_File "$_target" "${_directory}/."
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi


        # copy license file
        _target="${PROJECT_PATH_ROOT}/${PROJECT_PATH_RESOURCES}/licenses/LICENSE-EN.pdf"
        I18N_Copy "$_target" "$_directory"
        FS_Copy_File "$_target" "${_directory}/."
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi


        # report status
        return 0
}
