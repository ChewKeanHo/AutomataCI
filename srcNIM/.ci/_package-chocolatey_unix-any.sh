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




PACKAGE_Assemble_CHOCOLATEY_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS_Is_Target_A_Chocolatey "$_target") -ne 0 ]; then
                return 10 # not applicable
        fi


        # assemble the package
        ___source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/"
        ___dest="${_directory}/Data/${PROJECT_PATH_SOURCE}"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/.ci/"
        ___dest="${_directory}/Data/${PROJECT_PATH_SOURCE}/.ci"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_NIM}/"
        ___dest="${_directory}/Data/${PROJECT_NIM}"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_NIM}/.ci/"
        ___dest="${_directory}/Data/${PROJECT_NIM}/.ci"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/automataCI/"
        ___dest="${_directory}/Data/automataCI"
        I18N_Assemble "$___source" "$___dest"
        FS_Make_Directory "$___dest"
        FS_Copy_All "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/CONFIG.toml"
        ___dest="${_directory}/Data"
        I18N_Assemble "$___source" "$___dest"
        FS_Copy_File "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/icon-128x128.png"
        ___dest="${_directory}/icon.png"
        I18N_Assemble "$___source" "$___dest"
        FS_Copy_File "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi

        ___source="${PROJECT_PATH_ROOT}/README.md"
        ___dest="${_directory}/README.md"
        I18N_Assemble "$___source" "$___dest"
        FS_Copy_File "$___source" "$___dest"
        if [ $? -ne 0 ]; then
                I18N_Assemble_Failed
                return 1
        fi


        # REQUIRED: chocolatey required tools\ directory
        ___dest="${_directory}/tools"
        I18N_Create "$___dest"
        FS_Make_Directory "${_directory}/tools"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # OPTIONAL: chocolatey tools\chocolateyBeforeModify.ps1
        ___dest="${_directory}/tools/chocolateyBeforeModify.ps1"
        I18N_Create "$___dest"
        FS_Write_File "$___dest" "\
# REQUIRED - BEGIN EXECUTION
Write-Host \"Performing pre-configurations...\"
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # REQUIRED: chocolatey tools\chocolateyinstall.ps1
        ___dest="${_directory}/tools/chocolateyinstall.ps1"
        I18N_Create "$___dest"
        FS_Write_File "$___dest" "\
# REQUIRED - PREPARING INSTALLATION
\$tools_dir = \"\$(Split-Path -Parent -Path \$MyInvocation.MyCommand.Definition)\"
\$data_dir = \"\$(Split-Path -Parent -Path \$tools_dir)\\\\Data\"
\$root_dir = \"\$(Split-Path -Parent -Path \$root_dir)\"
\$current_dir = (Get-Location).Path




# REQUIRED - BEGIN EXECUTION
# Materialize the binary
Write-Host \"Building ${PROJECT_SKU} (${PROJECT_VERSION})...\"
Set-Location \"\$data_dir\"
.\\\\automataCI\\\\ci.sh.ps1 setup
if (\$LASTEXITCODE -ne 0) {
        Set-Location \"\$current_dir\"
        Set-PowerShellExitCode 1
        return
}

.\\\\automataCI\\\\ci.sh.ps1 prepare
if (\$LASTEXITCODE -ne 0) {
        Set-Location \"\$current_dir\"
        Set-PowerShellExitCode 1
        return
}

.\\\\automataCI\\\\ci.sh.ps1 materialize
if (\$LASTEXITCODE -ne 0) {
        Set-Location \"\$current_dir\"
        Set-PowerShellExitCode 1
        return
}

if (-not (Test-Path \"\${data_dir}\\\\bin\\\\${PROJECT_SKU}.exe\")) {
        Set-Location \"\$current_dir\"
        Write-Host \"Compile Failed. Missing executable.\"
        Set-PowerShellExitCode 1
        return
}


# Install
Write-Host \"assembling workspace for installation...\"
if (Test-Path -PathType Container -Path \"\${data_dir}\\\\bin\") {
        Move-Item -Path \"\${data_dir}\\\\bin\" -Destination \"\${root_dir}\"
}
if (Test-Path -PathType Container -Path \"\${data_dir}\\\\lib\") {
        Move-Item -Path \"\${data_dir}\\\\lib\" -Destination \"\${root_dir}\"
}
Set-Location \"\$current_dir\"
Remove-Item \$data_dir -Force -Recurse -ErrorAction SilentlyContinue
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # REQUIRED: chocolatey tools\chocolateyuninstall.ps1
        ___dest="${_directory}/tools/chocolateyuninstall.ps1"
        I18N_Create "$___dest"
        FS_Write_File "$___dest" "\
# REQUIRED - PREPARING UNINSTALLATION
Write-Host \"Uninstalling ${PROJECT_SKU} (${PROJECT_VERSION})...\"
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # REQUIRED: chocolatey xml.nuspec file
        ___dest="${_directory}/${PROJECT_SKU}.nuspec"
        I18N_Create "$___dest"
        FS_Write_File "$___dest" "\
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
                <readme>README.md</readme>
                <icon>icon.png</icon>
        </metadata>
        <dependencies>
                <dependency id=\"chocolatey\" version=\"0.9.8.21\" />
                <dependency id=\"nim\" version=\"2.0.0\" />
                <dependency id=\"gcc-arm-embedded\" version=\"10.3.1\" />
                <dependency id=\"mingw\" version=\"13.2.0\" />
        </dependencies>
        <files>
                <file src=\"README.md\" target=\"README.md\" />
                <file src=\"icon.png\" target=\"icon.png\" />
                <file src=\"Data\\\\**\" target=\"Data\" />
                <file src=\"tools\\\\**\" target=\"tools\" />
        </files>
</package>
"
        if [ $? -ne 0 ]; then
                I18N_Create_Failed
                return 1
        fi


        # report status
        return 0
}
