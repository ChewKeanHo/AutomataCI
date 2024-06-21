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




PACKAGE_Assemble_MSI_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate input
        case "$_target_os" in
        any|windows)
                ;;
        *)
                return 10 # not supported
                ;;
        esac

        case "$_target_arch" in
        any|amd64)
                ;;
        arm64|i386|arm)
                return 10 # wixl can only support amd64
                ;;
        *)
                return 10 # not supported
                ;;
        esac


        # execute
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                # unpack to the designated lib/ directory
                __dest="${_directory}/lib"

                if [ $(FS_Is_Target_A_NPM "$_target") -eq 0 ]; then
                        return 10 # not applicable
                elif [ $(FS_Is_Target_A_TARGZ "$_target") -eq 0 ]; then
                        # unpack library
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        TAR_Extract_GZ "$__dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                elif [ $(FS_Is_Target_A_TARXZ "$_target") -eq 0 ]; then
                        # unpack library
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        TAR_Extract_XZ "$__dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                elif [ $(FS_Is_Target_A_ZIP "$_target") -eq 0 ]; then
                        # unpack library
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        ZIP_Extract "$__dest" "$_target"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                else
                        # copy library file
                        __dest="${__dest}/$(FS_Get_File "${_target}")"
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        FS_Copy_File "$_target" "$__dest"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                fi
        elif [ $(FS_Is_Target_A_WASM_JS "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM "$_target") -eq 0 ]; then
                return 10 # not applicable
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
                # copy main program to the designated bin/ directory
                __dest="${_directory}/bin/${PROJECT_SKU}.exe"

                I18N_Assemble "$_target" "$__dest"
                FS_Make_Housing_Directory "$__dest"
                FS_Copy_File "$_target" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi
        fi


        # copy README.md into the designated docs/ directory
        __source="${PROJECT_PATH_ROOT}/${PROJECT_README}"
        __dest="${_directory}/docs/${PROJECT_README}"
        I18N_Assemble "$__source" "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # copy user guide files to the designated docs/ directory
        for __source in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/USER-GUIDES"*.pdf; do
                FS_Is_Target_Exist "$__source"
                if [ $? -ne 0 ]; then
                        continue
                fi

                __dest="${_directory}/docs/$(FS_Get_File "$__source")"
                I18N_Copy "$__source" "$__dest"
                FS_Copy_File "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        done


        # copy PDF license files to the designated docs/ directory
        for __source in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/licenses/LICENSE"*.pdf; do
                FS_Is_Target_Exist "$__source"
                if [ $? -ne 0 ]; then
                        continue
                fi

                __dest="${_directory}/docs/$(FS_Get_File "$__source")"
                I18N_Copy "$__source" "$__dest"
                FS_Copy_File "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        done


        # copy RTF license files to the designated docs/ directory
        for __source in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/licenses/LICENSE"*.rtf; do
                FS_Is_Target_Exist "$__source"
                if [ $? -ne 0 ]; then
                        continue
                fi

                __dest="${_directory}/docs/$(FS_Get_File "$__source")"
                I18N_Copy "$__source" "$__dest"
                FS_Copy_File "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        done


        # copy icon ico file to the designated base directory
        __source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/icon.ico"
        __dest="${_directory}/icon.ico"
        I18N_Assemble "$__source" "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # copy MSI banner jpg file to the designated base directory
        __source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/msi-banner.jpg"
        __dest="${_directory}/msi-banner.jpg"
        I18N_Copy "$__source" "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi


        # copy MSI dialog jpg file to the designated base directory
        __source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/msi-dialog.jpg"
        __dest="${_directory}/msi-dialog.jpg"
        I18N_Copy "$__source" "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Copy_Failed
                return 1
        fi


        ## OPTIONAL - create a '[LANG].wxs' recipe if you wish to override one
        ##            and place it inside the designated base directory.
        ##            Otherwise, AutomataCI shall create one for you using its
        ##            packaging structure.


        # report status
        return 0
}
