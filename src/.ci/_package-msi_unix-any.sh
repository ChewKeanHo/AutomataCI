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
. "${LIBS_AUTOMATACI}/services/io/strings.sh"
. "${LIBS_AUTOMATACI}/services/i18n/translations.sh"
. "${LIBS_AUTOMATACI}/services/crypto/random.sh"




PACKAGE_Assemble_MSI_Content() {
        _target="$1"
        _directory="$2"
        _target_name="$3"
        _target_os="$4"
        _target_arch="$5"


        # package based on target's nature
        if [ $(FS_Is_Target_A_MSI "$_target") -ne 0 ]; then
                return 10 # not applicable
        fi


        # validate critical inputs
        if [ -z "$PRODUCT_APP_UUID" ]; then
                return 1
        fi


        # Assemble all files across all languages. Checking is not required
        # since it will be checked during the scripting phase.
        __build_path="${PROJECT_PATH_ROOT}/${PROJECT_PATH_BUILD}"
        __source_path="${PROJECT_PATH_ROOT}/${PROJECT_PATH_SOURCE}"
        __files="\
${__build_path}/${PROJECT_SKU}_windows-amd64.exe|none
${__build_path}/${PROJECT_SKU}_windows-arm64.exe|none
${__build_path}/${PROJECT_SKU}_windows-i386.exe|none
${__build_path}/${PROJECT_SKU}_windows-arm.exe|none
${__source_path}/licenses/LICENSE_en.rtf|LICENSE_en.rtf
${__source_path}/licenses/LICENSE_en.rtf|LICENSE_zh-hans.rtf
${__source_path}/licenses/LICENSE-EN.pdf|LICENSE_en.pdf
${__source_path}/licenses/LICENSE-EN.pdf|LICENSE_zh-hans.pdf
${__source_path}/docs/USER-GUIDES-EN.pdf|USER-GUIDES_en.pdf
${__source_path}/docs/USER-GUIDES-EN.pdf|USER-GUIDES_zh-hans.pdf
${__source_path}/icons/icon.ico|none
${__source_path}/icons/msi-banner_en.jpg|none
${__source_path}/icons/msi-banner_zh-hans.jpg|none
${__source_path}/icons/msi-dialog_en.jpg|none
${__source_path}/icons/msi-dialog_zh-hans.jpg|none
"
        __selections="\
amd64|en
amd64|zh-hans
arm64|en
arm64|zh-hans
i386|en
i386|zh-hans
arm|en
arm|zh-hans
"


        # Assemble all files across all languages. Checking is not required
        # since it will be checked during the scripting phase.
        old_IFS="$IFS"
        printf -- '%s' "$__files" | while IFS="" read -r __line || [ -n "$__line" ]; do
                ## parse line
                __target="${__line%%|*}"
                __dest="${__line##*|}"

                ## validate inputs
                if [ ! -z "$_dest" ] && [ ! "$__dest" = "none" ]; then
                        __dest="${_directory}/${__dest}"
                else
                        __dest="$_directory"
                fi

                ## execute
                I18N_Assemble "$__target" "$__dest"
                if [ -e "$__target" ]; then
                        FS_Copy_File "$__target" "$__dest" &> /dev/null
                fi
        done
        IFS="$__old_IFS" && unset __old_IFS


        # generate all arch & i18n independent variables and tags
        __tag_ICON='Icon.exe'
        __const_ICON_SOURCE="${_directory}/icon.ico"

        __tag_DIR_INSTALL='INSTALLDIR'
        __tag_ARP_INSTALL_LOCATION='ARPINSTALLLOCATION'
        __const_INSTALLER_VERSION='400' # Windows Installer 4.0 (included in Vista)
        __const_INSTALLER_COMPRESSED_MODE='yes' # 'yes'|'no' only
        __const_INSTALLER_INSTALL_SCOPE='perMachine'
        __const_INSTALLER_REGISTRY_KEY="\
Software\\\\${PROJECT_CONTACT_NAME}\\\\InstalledProducts\\\\${PROJECT_NAME}"
        __const_INSTALLER_REGISTRY_NAME='InstallLocation'

        __tag_COMPONENT_BIN='ComponentBin'
        __uuid_COMPONENT_BIN="$(RANDOM_Create_UUID)" # replace with persistent one
        __tag_COMPONENT_BIN_OPTIONAL='ComponentBinOptional'
        __uuid_COMPONENT_BIN_OPTIONAL="$(RANDOM_Create_UUID)" # replace with persistent one
        __tag_COMPONENT_CONFIG='ComponentConfig'
        __uuid_COMPONENT_CONFIG="$(RANDOM_Create_UUID)" # replace with persistent one
        __tag_COMPONENT_CONFIG_OPTIONAL='ComponentConfigOptional'
        __uuid_COMPONENT_CONFIG_OPTIONAL="$(RANDOM_Create_UUID)" # replace with persistent one
        __tag_COMPONENT_LIB='ComponentLib'
        __uuid_COMPONENT_LIB="$(RANDOM_Create_UUID)" # replace with persistent one
        __tag_COMPONENT_LIB_OPTIONAL='ComponentLibOptional'
        __uuid_COMPONENT_LIB_OPTIONAL="$(RANDOM_Create_UUID)" # replace with persistent one
        __tag_COMPONENT_DOCS='ComponentDocs'
        __uuid_COMPONENT_DOCS="$(RANDOM_Create_UUID)" # replace with persistent one
        __tag_COMPONENT_DOCS_OPTIONAL='ComponentDocsOptional'
        __uuid_COMPONENT_DOCS_OPTIONAL="$(RANDOM_Create_UUID)" # replace with persistent one

        __tag_COMPONENT_INSTALLER='INSTALLDIR_comp'
        __uuid_COMPONENT_INSTALLER="$(RANDOM_Create_UUID)" # replace with persistent one
        __tag_COMPONENT_REGISTRIES='RegValInstallLocation_comp'
        __uuid_COMPONENT_REGISTRIES="$(RANDOM_Create_UUID)" # replace with persistent one

        __tag_FEATURE_ID='FeaturesAll'
        __tag_FEATURE_MAIN_ID='FeaturesMain'
        __tag_FEATURE_BIN_ID='FeaturesBin'
        __tag_FEATURE_CONFIG_ID='FeaturesConfig'
        __tag_FEATURE_LIB_ID='FeaturesLib'
        __tag_FEATURE_DOCS_ID='FeaturesDocs'


        # script the .wxs XML file (MSItools version)
        old_IFS="$IFS"
        printf -- '%s' "$__selections" | while IFS="" read -r __line || [ -n "$__line" ]; do
                # parse line
                __arch="$(STRINGS_To_Lowercase "${__line%%|*}")"
                __line="${__line#*|}"

                __i18n="$(STRINGS_To_Lowercase "${__line%%|*}")"
                __line="${__line#*|}"


                # generate all arch-specific variables and validate readiness for compilation
                case "$__arch" in
                amd64)
                        __var_DIR_PROGRAM_FILES="ProgramFiles64Folder"
                        __var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE="\
Unfortunately, you can only install this package on a 64-bit Windows."
                        __var_INSTALLER_REQUIRED_VERSION_CONDITION="<![CDATA[VersionNT64]]>"
                        ;;
                arm64)
                        __var_DIR_PROGRAM_FILES="ProgramFiles64Folder"
                        __var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE="\
Unfortunately, you can only install this package on a 64-bit Windows."
                        __var_INSTALLER_REQUIRED_VERSION_CONDITION="<![CDATA[VersionNT64]]>"
                        ;;
                i386)
                        __var_DIR_PROGRAM_FILES="ProgramFilesFolder"
                        __var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE="\
Unfortunately, you can only install this package on a 32-bit Windows."
                        __var_INSTALLER_REQUIRED_VERSION_CONDITION="<![CDATA[NOT VersionNT64]]>"
                        ;;
                arm)
                        __var_DIR_PROGRAM_FILES="ProgramFilesFolder"
                        __var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE="\
Unfortunately, you can only install this package on a 32-bit Windows."
                        __var_INSTALLER_REQUIRED_VERSION_CONDITION="<![CDATA[NOT VersionNT64]]>"
                        ;;
                *)
                        return 1
                        ;;
                esac


                # check required executables for packaging
                __var_MAIN_EXE_SOURCE="${_directory}/${PROJECT_SKU}_windows-${__arch}.exe"
                I18N_Check "${__var_MAIN_EXE_SOURCE}"
                FS_Is_File "$__var_MAIN_EXE_SOURCE"
                if [ $? -ne 0 ]; then
                        I18N_Check_Failed_Skipped
                        continue
                fi


                # generate all i18n variables and validate readiness for compilation
                _wxs="${PROJECT_SKU}_${PROJECT_VERSION}"
                case "$__i18n" in
                zh-hans)
                        ## Simplified Chinese (International)
                        __i18n="zh-hans"

                        ## NOTE: MSFT uses LCID instead of ISO indicator. Refer:
                        ##       https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/70feba9f-294e-491e-b6eb-56532684c37f
                        __var_LANGUAGE_ID='2052'

                        ## NOTE: DO NOT change the format. AutomataCI relies on
                        ##       it to parse wix4 culture settings.
                        ##       https://wixtoolset.org/docs/tools/wixext/wixui/#localization
                        _wxs="${_wxs}_zh-CN"

                        __var_INSTALLER_DESCRIPTION="\
${PROJECT_NAME} (${PROJECT_VERSION}) 安装包"
                        __var_INSTALLER_COMMENTS="(C) ${PROJECT_CONTACT_NAME}"

                        __var_INSTALLER_BANNER_SOURCE="${_directory}/msi-banner_${__i18n}.jpg"
                        __var_INSTALLER_DIALOG_SOURCE="${_directory}/msi-dialog_${__i18n}.jpg"

                        __var_INSTALLER_DOWNGRADE_COMMENT="\
您的${PROJECT_NAME}已经是同样|更新版本。如此就不需要任何步骤了。谢谢。
"

                        __var_MAIN_LICENSE_SOURCE="${_directory}/LICENSE_zh-hans.pdf"

                        __var_USER_GUIDE_ID='DocsUserGuideZHHANS'
                        __var_USER_GUIDE_SOURCE="${_directory}/USER-GUIDES_zh-hans.pdf"

                        __var_FEATURE_TITLE="${PROJECT_NAME}"
                        __var_FEATURE_DESCRIPTION='完整全部包装。'

                        __var_FEATURE_MAIN_TITLE='主要元件配套'
                        __var_FEATURE_MAIN_DESCRIPTION='所有第一重要无法缺乏的元件。'

                        __var_FEATURE_BIN_TITLE='软件类元件配套'
                        __var_FEATURE_BIN_DESCRIPTION='所有可有可无的可多加软件类元件。'

                        __var_FEATURE_CONFIG_TITLE='配置类元件配套'
                        __var_FEATURE_CONFIG_DESCRIPTION='所有可有可无的可多加配置类元件。'

                        __var_FEATURE_LIB_TITLE='代码库类元件配套'
                        __var_FEATURE_LIB_DESCRIPTION='所有可有可无的可多加代码库类元件。'

                        __var_FEATURE_DOCS_TITLE='文件类元件配套'
                        __var_FEATURE_DOCS_DESCRIPTION='所有可有可无的可多加文件类元件。'
                        ;;
                *)
                        # default to English (International)
                        __i18n="en"

                        ## NOTE: MSFT uses LCID instead of ISO indicator. Refer:
                        ##       https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/70feba9f-294e-491e-b6eb-56532684c37f
                        __var_LANGUAGE_ID='1033'

                        ## NOTE: DO NOT change the format. AutomataCI relies on
                        ##       it to parse wix4 culture settings.
                        ##       https://wixtoolset.org/docs/tools/wixext/wixui/#localization
                        _wxs="${_wxs}_en-US"

                        __var_INSTALLER_DESCRIPTION="\
${PROJECT_NAME} (${PROJECT_VERSION}) Installer"
                        __var_INSTALLER_COMMENTS="(C) ${PROJECT_CONTACT_NAME}"

                        __var_INSTALLER_BANNER_SOURCE="${_directory}/msi-banner_${__i18n}.jpg"
                        __var_INSTALLER_DIALOG_SOURCE="${_directory}/msi-dialog_${__i18n}.jpg"

                        __var_INSTALLER_DOWNGRADE_COMMENT="\
Your ${PROJECT_NAME} is the same/later version. No further action is required. Thank you.
"

                        __var_MAIN_LICENSE_SOURCE="${_directory}/LICENSE_en.pdf"

                        __var_USER_GUIDE_ID='DocsUserGuideEN'
                        __var_USER_GUIDE_SOURCE="${_directory}/USER-GUIDES_en.pdf"

                        __var_FEATURE_TITLE="${PROJECT_NAME}"
                        __var_FEATURE_DESCRIPTION='The complete package.'

                        __var_FEATURE_MAIN_TITLE='Main Components'
                        __var_FEATURE_MAIN_DESCRIPTION='All core and critical components.'

                        __var_FEATURE_BIN_TITLE='Additional Components'
                        __var_FEATURE_BIN_DESCRIPTION='All optional addition components.'

                        __var_FEATURE_CONFIG_TITLE='Additional Configurations Components'
                        __var_FEATURE_CONFIG_DESCRIPTION='All optional configurations components.'

                        __var_FEATURE_LIB_TITLE='Additional Libraries Components'
                        __var_FEATURE_LIB_DESCRIPTION='All optional libraries components.'

                        __var_FEATURE_DOCS_TITLE='Documentation Components'
                        __var_FEATURE_DOCS_DESCRIPTION='All documentations components.'
                        ;;
                esac
                _wxs="${_directory}/${_wxs}_windows-${__arch}.wxs"


                # check required files for packaging
                I18N_Check "$__var_MAIN_LICENSE_SOURCE"
                FS_Is_File "$__var_MAIN_LICENSE_SOURCE"
                if [ $? -ne 0 ]; then
                        I18N_Check_Failed_Skipped
                        continue
                fi

                I18N_Check "$__var_USER_GUIDE_SOURCE"
                FS_Is_File "$__var_USER_GUIDE_SOURCE"
                if [ $? -ne 0 ]; then
                        I18N_Check_Failed_Skipped
                        continue
                fi

                I18N_Check "$_wxs"
                FS_Is_File "$_wxs"
                if [ $? -eq 0 ]; then
                        I18N_Check_Failed
                        return 1
                fi


                # creating wxs recipe
                I18N_Create "$_wxs"
                FS_Write_File "$_wxs" "\
<?xml version='1.0' encoding='UTF-8'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
        <Product Id='*'
                Name='${PROJECT_NAME}'
                Language='${__var_LANGUAGE_ID}'
                Version='${PROJECT_VERSION}'
                Manufacturer='${PROJECT_CONTACT_NAME}'
                UpgradeCode='${PRODUCT_APP_UUID}'
        >
                <Package Id='*'
                        Keywords='Installer'
                        Description='${__var_INSTALLER_DESCRIPTION}'
                        InstallerVersion='${__const_INSTALLER_VERSION}'
                        Compressed='${__const_INSTALLER_COMPRESSED_MODE}'
                        InstallScope='${__const_INSTALLER_INSTALL_SCOPE}'
                        Comments='${__var_INSTALLER_COMMENTS}'
                />
                <Icon Id='${__tag_ICON}' SourceFile='${__const_ICON_SOURCE}' />
                <MajorUpgrade AllowSameVersionUpgrades='yes'
                        DowngradeErrorMessage='${__var_INSTALLER_DOWNGRADE_COMMENT}'
                />

                <!-- Configure 'Add/Remove Programs' interfaces -->
                <Property Id='ARPPRODUCTICON' Value='${__tag_ICON}' />
                <Property Id='ARPHELPLINK' Value='${PROJECT_CONTACT_WEBSITE}' />
                <Property Id='ARPNOREPAIR' Value='yes' Secure='yes' /><!-- Remove repair -->
                <Property Id='ARPNOMODIFY' Value='yes' Secure='yes' /><!-- Remove modify -->

                <!-- Configure installer main sequences -->
                <CustomAction Id='Set${__tag_ARP_INSTALL_LOCATION}'
                        Property='${__tag_ARP_INSTALL_LOCATION}'
                        Value='[${__tag_DIR_INSTALL}]' />
                <InstallExecuteSequence>
                        <!-- Determine the install location after validated by the installer -->
                        <Custom Action='Set${__tag_ARP_INSTALL_LOCATION}'
                                After='InstallValidate'
                        ></Custom>
                </InstallExecuteSequence>

                <!-- Configure backward compatible multi-mediums (e.g. Floppy disks, CDs) -->
                <Media Id='1' Cabinet='media1.cab' EmbedCab='yes' />

                <!-- Configure ${__tag_DIR_INSTALL} from CMD -->
                <CustomAction Id='SaveCMD${__tag_DIR_INSTALL}'
                        Property='CMDLINE_${__tag_DIR_INSTALL}'
                        Value='[${__tag_DIR_INSTALL}]'
                        Execute='firstSequence'
                />
                <CustomAction Id='SetFromCMD${__tag_DIR_INSTALL}'
                        Property='${__tag_DIR_INSTALL}'
                        Value='[${__tag_DIR_INSTALL}]'
                        Execute='firstSequence'
                />
                <InstallUISequence>
                        <Custom Action='SaveCMD${__tag_DIR_INSTALL}' Before='AppSearch' />
                        <Custom Action='SetFromCMD${__tag_DIR_INSTALL}' After='AppSearch'>
                                CMDLINE_${__tag_DIR_INSTALL}
                        </Custom>
                </InstallUISequence>
                <InstallExecuteSequence>
                        <Custom Action='SaveCMD${__tag_DIR_INSTALL}' Before='AppSearch' />
                        <Custom Action='SetFromCMD${__tag_DIR_INSTALL}' After='AppSearch'>
                                CMDLINE_${__tag_DIR_INSTALL}
                        </Custom>
                </InstallExecuteSequence>
                <Property Id='${__tag_DIR_INSTALL}'>
                        <RegistrySearch Id='DetermineInstallLocation'
                                Type='raw'
                                Root='HKLM'
                                Key='${__const_INSTALLER_REGISTRY_KEY}'
                                Name='${__const_INSTALLER_REGISTRY_NAME}'
                        />
                </Property>


"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi


                # Assemble Components
                FS_Append_File "$_wxs" "\
                <Directory Id='TARGETDIR' Name='SourceDir'>
                <Directory Id='${__var_DIR_PROGRAM_FILES}'
                ><Directory Id='${__tag_DIR_INSTALL}' Name='${PROJECT_NAME}'
                >
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi

                if [ "$__packager_type" = "full" ]; then
                        FS_Append_File "$_wxs" "\
                        <!-- Uninstallation component -->
                        <Component Id='${__tag_COMPONENT_INSTALLER}'
                                Guid='${__uuid_COMPONENT_INSTALLER}'
                        >
                                <CreateFolder />
                                <RemoveFile Id='RemoveFilesFromAppDirectory'
                                        Name='*.*'
                                        On='uninstall' />
                        </Component>
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi
                fi


                FS_Append_File "$_wxs" "\
                        <Directory Id='FolderBin' Name='bin'>
                                <!-- Compulsory Executable Here -->
                                <Component Id='${__tag_COMPONENT_BIN}'
                                        Guid='${__uuid_COMPONENT_BIN}'
                                >
                                        <File Id='EXEMain'
                                                Source='${__var_MAIN_EXE_SOURCE}'
                                                KeyPath='yes'
                                        />
                                </Component>

                                <!-- Optional Executable Here -->
                                <Component Id='${__tag_COMPONENT_BIN_OPTIONAL}'
                                        Guid='${__uuid_COMPONENT_BIN_OPTIONAL}'
                                >
                                </Component>
                        </Directory>
                        <Directory Id='FolderConfig' Name='config'>
                                <!-- Compulsory Config Files Here -->
                                <Component Id='${__tag_COMPONENT_CONFIG}'
                                        Guid='${__uuid_COMPONENT_CONFIG}'
                                >
                                </Component>

                                <!-- Optional Config Files Here -->
                                <Component Id='${__tag_COMPONENT_CONFIG_OPTIONAL}'
                                                Guid='${__uuid_COMPONENT_CONFIG_OPTIONAL}'
                                >
                                </Component>
                        </Directory>
                        <Directory Id='FolderLib' Name='lib'>
                                <!-- Compulsory Libraries Files Here -->
                                <Component Id='${__tag_COMPONENT_LIB}'
                                        Guid='${__uuid_COMPONENT_LIB}'
                                >
                                </Component>

                                <!-- Optional Libraries Files Here -->
                                <Component Id='${__tag_COMPONENT_LIB_OPTIONAL}'
                                                Guid='${__uuid_COMPONENT_LIB_OPTIONAL}'
                                >
                                </Component>
                        </Directory>
                        <Directory Id='FolderDocs' Name='docs'>
                                <!-- Compulsory Docs Files Here -->
                                <Component Id='${__tag_COMPONENT_DOCS}'
                                        Guid='${__uuid_COMPONENT_DOCS}'
                                >
                                        <File Id='DOCSLicense'
                                                Source='${__var_MAIN_LICENSE_SOURCE}'
                                                KeyPath='yes'
                                        />
                                </Component>

                                <!-- Optional Docs Files Here -->
                                <Component Id='${__tag_COMPONENT_DOCS_OPTIONAL}'
                                                Guid='${__uuid_COMPONENT_DOCS_OPTIONAL}'
                                >
                                        <File Id='${__var_USER_GUIDE_ID}'
                                                Source='${__var_USER_GUIDE_SOURCE}'
                                                KeyPath='yes'
                                        />
                                </Component>
                        </Directory>
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi

                FS_Append_File "$_wxs" "\
                </Directory></Directory>
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi

                FS_Append_File "$_wxs" "\
                        <Component Id='${__tag_COMPONENT_REGISTRIES}'
                                Guid='${__uuid_COMPONENT_REGISTRIES}'
                        >
                                <RegistryKey Root='HKLM'
                                        Key='${__const_INSTALLER_REGISTRY_KEY}'
                                >
                                        <RegistryValue
                                                Name='${__const_INSTALLER_REGISTRY_NAME}'
                                                Value='[${__tag_DIR_INSTALL}]'
                                                Type='string'
                                                KeyPath='yes'
                                        />
                                        <!-- DO NOT use default registries here -->
                                        <!-- They will be removed upon uninstall (upgrade) -->
                                        <!-- To add: refer to the compulsory Registry above. -->
                                </RegistryKey>
                        </Component>
                </Directory>


"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi


                # Define all feature components
                FS_Append_File "$_wxs" "\
                <Feature Id='${__tag_FEATURE_ID}'
                        Title='${__var_FEATURE_TITLE}'
                        Description='${__var_FEATURE_DESCRIPTION}'
                        Level='1'
                        Display='expand'
                        ConfigurableDirectory='${__tag_DIR_INSTALL}'
                >
                        <Feature Id='${__tag_FEATURE_MAIN_ID}'
                                Title='${__var_FEATURE_MAIN_TITLE}'
                                Description='${__var_FEATURE_MAIN_DESCRIPTION}'
                                Level='1'
                        >
                                <ComponentRef Id='${__tag_COMPONENT_BIN}' />
                                <ComponentRef Id='${__tag_COMPONENT_CONFIG}' />
                                <ComponentRef Id='${__tag_COMPONENT_LIB}' />
                                <ComponentRef Id='${__tag_COMPONENT_DOCS}' />
                        </Feature>
                        <Feature Id='${__tag_FEATURE_BIN_ID}'${__var_OPTIONALITY}
                                Title='${__var_FEATURE_BIN_TITLE}'
                                Description='${__var_FEATURE_BIN_DESCRIPTION}'
                                Level='1'
                        >
                                <ComponentRef Id='${__tag_COMPONENT_BIN_OPTIONAL}' />
                        </Feature>
                        <Feature Id='${__tag_FEATURE_CONFIG_ID}'${__var_OPTIONALITY}
                                Title='${__var_FEATURE_CONFIG_TITLE}'
                                Description='${__var_FEATURE_CONFIG_DESCRIPTION}'
                                Level='1'
                        >
                                <ComponentRef Id='${__tag_COMPONENT_CONFIG_OPTIONAL}' />
                        </Feature>
                        <Feature Id='${__tag_FEATURE_LIB_ID}'${__var_OPTIONALITY}
                                Title='${__var_FEATURE_LIB_TITLE}'
                                Description='${__var_FEATURE_LIB_DESCRIPTION}'
                                Level='1'
                        >
                                <ComponentRef Id='${__tag_COMPONENT_LIB_OPTIONAL}' />
                        </Feature>
                        <Feature Id='${__tag_FEATURE_DOCS_ID}'${__var_OPTIONALITY}
                                Title='${__var_FEATURE_DOCS_TITLE}'
                                Description='${__var_FEATURE_DOCS_DESCRIPTION}'
                                Level='1'
                        >
                                <ComponentRef Id='${__tag_COMPONENT_DOCS_OPTIONAL}' />
                        </Feature>
                </Feature>
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi


                # conclude the wxs write-up
                FS_Append_File "$_wxs" "\
        </Product>
</Wix>
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi
        done
        __exit=$?
        IFS="$__old_IFS" && unset __old_IFS

        case "$__exit" in
        0)
                ;;
        *)
                return $__exit
                ;;
        esac


        # report status
        return 0
}
