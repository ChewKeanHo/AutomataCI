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




# initialize
if [ "$PROJECT_PATH_ROOT" == "" ]; then
        >&2 printf "[ ERROR ] - Please run from ci.cmd instead!\n"
        return 1
fi

. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/os.sh"
. "${PROJECT_PATH_ROOT}/${PROJECT_PATH_AUTOMATA}/services/io/fs.sh"




PACKAGE::assemble_chocolatey_content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # validate project
        if [ $(FS_Is_Target_A_Source "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Docs "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Library "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM_JS "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_WASM "$_target") -eq 0 ]; then
                return 10 # not applicable
        elif [ $(FS_Is_Target_A_Chocolatey "$_target") -eq 0 ]; then
                : # accepted
        elif [ $(FS_Is_Target_A_Homebrew "$_target") -eq 0 ]; then
                return 10 # not applicable
        else
                return 10 # not applicable
        fi


        # assemble the package
        FS_Make_Directory "${_directory}/Data/${PROJECT_PATH_SOURCE}"
        FS_Copy_All \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/" \
                "${_directory}/Data/${PROJECT_PATH_SOURCE}"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_All "${PROJECT_PATH_ROOT}/${PROJECT_PYTHON}" "${_directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_All "${PROJECT_PATH_ROOT}/automataCI" "${_directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_File "${PROJECT_PATH_ROOT}/CONFIG.toml" "${_directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_File "${PROJECT_PATH_ROOT}/ci.cmd" "${_directory}/Data"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_File \
                "${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}/icons/icon-128x128.png" \
                "${_directory}/icon.png"
        if [ $? -ne 0 ]; then
                return 1
        fi

        FS_Copy_File \
                "${PROJECT_PATH_ROOT}/README.md" \
                "${_directory}/README.md"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # REQUIRED: chocolatey required tools\ directory
        FS_Make_Directory "${_directory}/tools"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # OPTIONAL: chocolatey tools\chocolateyBeforeModify.ps1
        OS::print_status info "scripting tools/chocolateyBeforeModify.ps1...\n"
        FS_Write_File "${_directory}/tools/chocolateyBeforeModify.ps1" "\
# REQUIRED - BEGIN EXECUTION
Write-Host \"Performing pre-configurations...\"
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # REQUIRED: chocolatey tools\chocolateyinstall.ps1
        OS::print_status info "scripting tools/chocolateyinstall.ps1...\n"
        FS_Write_File "${_directory}/tools/chocolateyinstall.ps1" "\
# REQUIRED - PREPARING INSTALLATION
\$tools_dir = \"\$(Split-Path -Parent -Path \$MyInvocation.MyCommand.Definition)\"
\$data_dir = \"\$(Split-Path -Parent -Path \$tools_dir)\\\\Data\"
\$root_dir = \"\$(Split-Path -Parent -Path \$root_dir)\"
\$current_dir = (Get-Location).Path




# REQUIRED - BEGIN EXECUTION
# Materialize the binary
Write-Host \"Building ${PROJECT_SKU} (${PROJECT_VERSION})...\"
Set-Location \"\$data_dir\"
.\\\\ci.cmd setup
if (\$LASTEXITCODE -ne 0) {
        Set-Location \"\$current_dir\"
        Set-PowerShellExitCode 1
        return
}

.\\\\ci.cmd prepare
if (\$LASTEXITCODE -ne 0) {
        Set-Location \"\$current_dir\"
        Set-PowerShellExitCode 1
        return
}

.\\\\ci.cmd materialize
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
Move-Item -Path \"\${data_dir}\\\\bin\" -Destination \"\${root_dir}\"
Move-Item -Path \"\${data_dir}\\\\lib\" -Destination \"\${root_dir}\"
Set-Location \"\$current_dir\"
Remove-Item \$data_dir -Force -Recurse -ErrorAction SilentlyContinue
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # REQUIRED: chocolatey tools\chocolateyuninstall.ps1
        OS::print_status info "scripting tools/chocolateyuninstall.ps1...\n"
        FS_Write_File "${_directory}/tools/chocolateyuninstall.ps1" "\
# REQUIRED - PREPARING UNINSTALLATION
Write-Host \"Uninstalling ${PROJECT_SKU} (${PROJECT_VERSION})...\"
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # REQUIRED: chocolatey xml.nuspec file
        OS::print_status info "scripting ${PROJECT_SKU}.nuspec...\n"
        FS_Write_File "${_directory}/${PROJECT_SKU}.nuspec" "\
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
                <dependency id=\"python\" version=\"3.12.0\" />
        </dependencies>
        <files>
                <file src=\"README.md\" target=\"README.md\" />
                <file src=\"icon.png\" target=\"icon.png\" />
                <file src=\"Data\**\" target=\"Data\" />
                <file src=\"tools\**\" target=\"tools\" />
        </files>
</package>
"
        if [ $? -ne 0 ]; then
                return 1
        fi


        # report status
        return 0
}
