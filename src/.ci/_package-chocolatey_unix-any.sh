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
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi

. "${LIBS_AUTOMATACI}/services/io/fs.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"




PACKAGE_Assemble_CHOCOLATEY_Content() {
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

        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
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
                        __dest="${__dest}/$(FS_Get_File "$_target")"
                        I18N_Assemble "$_target" "$__dest"
                        FS_Make_Directory "$__dest"
                        FS_Copy_File "$_target" "$__dest"
                        if [ $? -ne 0 ]; then
                                I18N_Assemble_Failed
                                return 1
                        fi
                fi

                _package="lib${PROJECT_SKU}"
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
                # copy main program
                __dest="${_directory}/bin/${PROJECT_SKU}.exe"

                I18N_Assemble "$_target" "$__dest"
                FS_Make_Housing_Directory "$__dest"
                FS_Copy_File "$_target" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Assemble_Failed
                        return 1
                fi

                _package="${PROJECT_SKU}"
        fi

        __source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/icon-128x128.png"
        __dest="${_directory}/icon.png"
        I18N_Assemble "$__source" "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        __source="${PROJECT_PATH_ROOT}/${PROJECT_README}"
        __dest="${_directory}/${PROJECT_README}"
        I18N_Assemble "$__source" "$__dest"
        FS_Copy_File "$__source" "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # REQUIRED: chocolatey required tools\ directory
        __dest="${_directory}/tools"
        I18N_Create "$__dest"
        FS_Make_Directory "$__dest"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # OPTIONAL: chocolatey tools\chocolateyBeforeModify.ps1
        __dest="${_directory}/tools/chocolateyBeforeModify.ps1"
        I18N_Create "$__dest"
        FS_Write_File "$__dest" "\
# REQUIRED - BEGIN EXECUTION
Write-Host \"Performing pre-configurations...\"
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # REQUIRED: chocolatey tools\chocolateyinstall.ps1
        __dest="${_directory}/tools/chocolateyinstall.ps1"
        I18N_Create "$__dest"
        FS_Write_File "$__dest" "\
# REQUIRED - PREPARING INSTALLATION
Write-Host \"Installing ${PROJECT_SKU} (${PROJECT_VERSION})...\"
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # REQUIRED: chocolatey tools\chocolateyuninstall.ps1
        __dest="${_directory}/tools/chocolateyuninstall.ps1"
        I18N_Create "$__dest"
        FS_Write_File "$__dest" "\
# REQUIRED - PREPARING UNINSTALLATION
Write-Host \"Uninstalling ${PROJECT_SKU} (${PROJECT_VERSION})...\"
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # REQUIRED: chocolatey xml.nuspec file
        __dest="${_directory}/${_package}.nuspec"
        I18N_Create "$__dest"
        FS_Write_File "$__dest" "\
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<package xmlns=\"http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd\">
        <metadata>
                <id>${PROJECT_SKU}</id>
                <title>${PROJECT_NAME}</title>
                <version>${PROJECT_VERSION}</version>
                <authors>${PROJECT_CONTACT_NAME}</authors>
                <owners>${PROJECT_CONTACT_NAME}</owners>
                <projectUrl>${PROJECT_CONTACT_WEBSITE}</projectUrl>
                <license type=\"expression\">${PROJECT_LICENSE}</license>
                <description>${PROJECT_PITCH}</description>
                <readme>${PROJECT_README}</readme>
                <icon>icon.png</icon>
        </metadata>
        <dependencies>
                <dependency id=\"chocolatey\" version=\"${PROJECT_CHOCOLATEY_VERSION}\" />
        </dependencies>
        <files>
                <file src=\"${PROJECT_README}\" target=\"${PROJECT_README}\" />
                <file src=\"icon.png\" target=\"icon.png\" />
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi

        FS_Is_Directory_Empty "${_directory}/bin"
        if [ $? -ne 0 ]; then
                FS_Append_File "$__dest" "\
                <file src=\"bin\\\\**\" target=\"bin\" />
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi
        fi

        FS_Is_Directory_Empty "${_directory}/lib"
        if [ $? -ne 0 ]; then
                FS_Append_File "$__dest" "\
                <file src=\"lib\\\\**\" target=\"lib\" />
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi
        fi

        FS_Append_File "$__dest" "\
        </files>
</package>
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # execute
        return 0
}
