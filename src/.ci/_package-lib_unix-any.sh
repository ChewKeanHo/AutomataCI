#!/bin/sh
# Copyright 2024 (Holloway) Chew, Kean Ho <hello@hollowaykeanho.com>
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
. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/archive/tar.sh"
. "${LIBS_AUTOMATACI}/services/archive/zip.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Assemble_LIB_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS_Is_Target_A_Library "$_target") -ne 0 ]; then
                return 10 # not applicable
        fi


        # execute
        _workspace="packagers-lib-$(FS_Get_File "$_target")"
        _workspace="${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/${_workspace}"
        FS_Remove_Silently "$_workspace"

        __dest="${_workspace}/lib"
        if [ $(FS_Is_Target_A_NPM "$_target") -eq 0 ]; then
                # copy over - do not further modify its content anymore
                __dest="lib${PROJECT_SKU}-NPM_${PROJECT_VERSION}_js-js.tgz"
                __dest="${_directory}/${__dest}"
                I18N_Copy "$_target" "$__dest"
                FS_Copy_File "$_target" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi

                return 0
        elif [ $(FS_Is_Target_A_TARGZ "$_target") -eq 0 ]; then
                # unpack library
                I18N_Assemble "$_target" "$__dest"
                FS_Make_Directory "$__dest"
                TAR_Extract_GZ "$__dest" "$_target"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        elif [ $(FS_Is_Target_A_TARXZ "$_target") -eq 0 ]; then
                # unpack library
                I18N_Assemble "$_target" "$__dest"
                FS_Make_Directory "$__dest"
                TAR_Extract_XZ "$__dest" "$_target"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
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
                # assumed it is a standalone library file
                I18N_Assemble "$_target" "$__dest"
                FS_Make_Directory "$__dest"
                FS_Copy_File "$_target" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi
        fi


        # sanity check before proceeding
        FS_Is_Directory_Empty "$__dest"
        if [ $? -eq 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # copy README.md
        __source="${PROJECT_PATH_ROOT}/${PROJECT_README}"
        __dest="${_workspace}/${PROJECT_README}"
        I18N_Assemble "$__source" "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # copy user guide files
        for __source in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/docs/USER-GUIDES"*.pdf; do
                FS_Is_Target_Exist "$__source"
                if [ $? -ne 0 ]; then
                        continue
                fi

                __dest="${_workspace}/$(FS_Get_File "$__source")"
                I18N_Copy "$__source" "$__dest"
                FS_Copy_File "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        done


        # copy license files
        for __source in "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/licenses/LICENSE"*.pdf; do
                FS_Is_Target_Exist "$__source"
                if [ $? -ne 0 ]; then
                        continue
                fi

                __dest="${_workspace}/$(FS_Get_File "$__source")"
                I18N_Copy "$__source" "$__dest"
                FS_Copy_File "$__source" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Copy_Failed
                        return 1
                fi
        done


        # assemble icon.png
        __source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/icon-128x128.png"
        __dest="${_workspace}/icon.png"
        I18N_Assemble "$__source" "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # begin packaging
        __current_path="$PWD" && cd "$_workspace"

        ## package tar.xz
        __dest="lib${PROJECT_SKU}_${PROJECT_VERSION}_${_target_os}-${_target_arch}.tar.xz"
        I18N_Create_Package "$__dest"
        __dest="${_directory}/${__dest}"
        TAR_Create_XZ "$__dest" "."
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                cd "$__current_path" && unset __current_path
                return 1
        fi

        ## package zip
        __dest="lib${PROJECT_SKU}_${PROJECT_VERSION}_${_target_os}-${_target_arch}.zip"
        I18N_Create_Package "$__dest"
        __dest="${_directory}/${__dest}"
        ZIP_Create "$__dest" "."
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                cd "$__current_path" && unset __current_path
                return 1
        fi

        ## package nupkg
        __acceptance="false"
        if [ $(STRINGS_To_Lowercase "$PROJECT_LICENSE_ACCEPTANCE_REQUIRED") = "true" ]; then
                __acceptance="true"
        fi

        __dest="lib${PROJECT_SKU}.nuspec"
        I18N_Create "$__dest"
        FS_Write_File "./${__dest}" "\
<?xml version='1.0' encoding='utf-8'?>
<package xmlns='http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd'>
        <metadata>
                <id>${PROJECT_SKU}</id>
                <version>${PROJECT_VERSION}</version>
                <authors>${PROJECT_CONTACT_NAME}</authors>
                <owners>${PROJECT_CONTACT_NAME}</owners>
                <projectUrl>${PROJECT_SOURCE_URL}</projectUrl>
                <title>${PROJECT_NAME}</title>
                <description>${PROJECT_PITCH}</description>
                <license>${PROJECT_LICENSE}</license>
                <requireLicenseAcceptance>${__acceptance}</requireLicenseAcceptance>
                <readme>${PROJECT_README}</readme>
                <icon>icon.png</icon>
        </metadata>
        <files>
                <file src=\"${PROJECT_README}\" target=\"${PROJECT_README}\" />
                <file src=\"icon.png\" target=\"icon.png\" />
                <file src=\"lib\\\\**\" target=\"lib\" />
        </files>
</package>
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                cd "$__current_path" && unset __current_path
                return 1
        fi

        __dest="lib${PROJECT_SKU}_${PROJECT_VERSION}_${_target_os}-${_target_arch}.nupkg"
        I18N_Create_Package "$__dest"
        __dest="${_directory}/${__dest}"
        ZIP_Create "$__dest" "."
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                cd "$__current_path" && unset __current_path
                return 1
        fi

        ## done - clean up
        cd "$__current_path" && unset __current_path


        # report status
        return 0
}
