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
. "${LIBS_AUTOMATACI}/services/compilers/msi.sh"
. "${LIBS_AUTOMATACI}/services/crypto/random.sh"
. "${LIBS_AUTOMATACI}/services/hestiaLOCALE/Vanilla.sh.ps1"
. "${LIBS_AUTOMATACI}/services/hestiaI18N/Vanilla.sh.ps1"




# initialize
if [ "$PROJECT_PATH_ROOT" = "" ]; then
        >&2 printf "[ ERROR ] - Please run me from automataCI/ci.sh.ps1 instead!\n"
        return 1
fi




PACKAGE_Seal_MSI() {
        __workspace="$1"
        __output_directory="$2"


        # obtain buildable target architecture
        _target_arch="$(FS_Get_File "$__workspace")"
        I18N_Check "MSI: '$_target_arch'"
        case "$_target_arch" in
        amd64)
                ;;
        *)
                I18N_Check_Incompatible_Skipped
                return 0 # wixl does not support other arch aside amd64
                ;;
        esac


        # validate icon.ico available
        __icon_filepath="${__workspace}/icon.ico"
        I18N_Check "$__icon_filepath"
        FS_Is_File "$__icon_filepath"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # validate msi-banner.jpg is available
        __banner_filepath="${__workspace}/msi-banner.jpg"
        I18N_Check "$__banner_filepath"
        FS_Is_File "$__banner_filepath"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # validate msi-dialog.jpg is available
        __dialog_filepath="${__workspace}/msi-dialog.jpg"
        I18N_Check "$__dialog_filepath"
        FS_Is_File "$__dialog_filepath"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # create wxs scripts by languages
        __old_IFS="$IFS"
        while IFS="" read -r __language || [ -n "$__language" ]; do
                # formulate destination path
                __dest="${__workspace}/${PROJECT_SKU}_${__language}_windows-${_target_arch}.wxs"
                I18N_Check_Availability "$__dest"
                FS_Is_File "$__dest"
                if [ $? -eq 0 ]; then
                        # user supplied - begin packaging
                        I18N_Package "$__dest"
                        MSI_Compile "$__dest" "$_target_arch" "$__language"
                        if [ $? -ne 0 ]; then
                                I18N_Package_Failed
                                return 1
                        fi

                        continue
                fi


                # creating wxs headers
                I18N_Create "$__dest"
                FS_Write_File "$__dest" "\
<?xml version='1.0' encoding='UTF-8'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
        <Product Id='*'
                Name=\"${PROJECT_NAME}\"
                Language='$(hestiaLOCALE_Get_LCID "$__language")'
                Version='${PROJECT_VERSION}'
                Manufacturer='${PROJECT_CONTACT_NAME}'
                UpgradeCode='${PRODUCT_APP_UUID}'
        >
                <Package Id='*'
                        Keywords='Installer'
                        Description=\"${PROJECT_NAME} (${PROJECT_VERSION})\"
                        InstallerVersion='${PROJECT_MSI_INSTALLER_VERSION_UNIX}'
                        Compressed='${PROJECT_MSI_COMPRESSED_MODE}'
                        InstallScope='${PROJECT_MSI_INSTALLER_SCOPE}'
                        Comments=\"(C) ${PROJECT_CONTACT_NAME}\"
                />

                <!-- Declare icon file -->
                <Icon Id='Icon.exe' SourceFile='${__icon_filepath}' />

                <!-- Configure upgrade settings -->
                <MajorUpgrade AllowSameVersionUpgrades='yes'
                        DowngradeErrorMessage=\"$(hestiaI18N_Translate_Already_Latest_Version \
                                                        "$__language")\"
                />

                <!-- Configure 'Add/Remove Programs' interfaces -->
                <Property Id='ARPPRODUCTICON' Value='Icon.exe' />
                <Property Id='ARPHELPLINK' Value='${PROJECT_CONTACT_WEBSITE}' />

                <!-- Remove repair -->
                <Property Id='ARPNOREPAIR' Value='yes' Secure='yes' />

                <!-- Remove modify -->
                <Property Id='ARPNOMODIFY' Value='yes' Secure='yes' />

                <!-- Configure installer main sequences -->
                <CustomAction Id='Set${PROJECT_MSI_ARP_INSTALL_LOCATION}'
                        Property='${PROJECT_MSI_ARP_INSTALL_LOCATION}'
                        Value='[${PROJECT_MSI_INSTALL_DIRECTORY}]' />
                <InstallExecuteSequence>
                        <!-- Determine the install location after validated by the installer -->
                        <Custom Action='Set${PROJECT_MSI_ARP_INSTALL_LOCATION}'
                                After='InstallValidate'
                        ></Custom>
                </InstallExecuteSequence>

                <!-- Configure backward compatible multi-mediums (e.g. Floppy disks, CDs) -->
                <Media Id='1' Cabinet='media1.cab' EmbedCab='yes' />

                <!-- Configure ${PROJECT_MSI_INSTALL_DIRECTORY} from CMD -->
                <CustomAction Id='SaveCMD${PROJECT_MSI_INSTALL_DIRECTORY}'
                        Property='CMDLINE_${PROJECT_MSI_INSTALL_DIRECTORY}'
                        Value='[${PROJECT_MSI_INSTALL_DIRECTORY}]'
                        Execute='firstSequence'
                />
                <CustomAction Id='SetFromCMD${PROJECT_MSI_INSTALL_DIRECTORY}'
                        Property='${PROJECT_MSI_INSTALL_DIRECTORY}'
                        Value='[${PROJECT_MSI_INSTALL_DIRECTORY}]'
                        Execute='firstSequence'
                />
                <InstallUISequence>
                        <Custom Action='SaveCMD${PROJECT_MSI_INSTALL_DIRECTORY}'
                                Before='AppSearch' />
                        <Custom Action='SetFromCMD${PROJECT_MSI_INSTALL_DIRECTORY}'
                                After='AppSearch'>CMDLINE_${PROJECT_MSI_INSTALL_DIRECTORY}</Custom>
                </InstallUISequence>
                <InstallExecuteSequence>
                        <Custom Action='SaveCMD${PROJECT_MSI_INSTALL_DIRECTORY}'
                                Before='AppSearch' />
                        <Custom Action='SetFromCMD${PROJECT_MSI_INSTALL_DIRECTORY}'
                                After='AppSearch'>CMDLINE_${PROJECT_MSI_INSTALL_DIRECTORY}</Custom>
                </InstallExecuteSequence>
                <Property Id='${PROJECT_MSI_INSTALL_DIRECTORY}'>
                        <RegistrySearch Id='DetermineInstallLocation'
                                Type='raw'
                                Root='HKLM'
                                Key='${PROJECT_MSI_REGISTRY_KEY}'
                                Name='${PROJECT_MSI_REGISTRY_NAME}'
                        />
                </Property>
                <Directory Id='TARGETDIR' Name='SourceDir'>
                <Directory Id='$(MSI_Get_Directory_Program_Files "${_target_arch}")'
                ><Directory Id='${PROJECT_SCOPE}DIR' Name='${PROJECT_SCOPE}'
                ><Directory Id='${PROJECT_MSI_INSTALL_DIRECTORY}' Name='${PROJECT_SKU}'
                >
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi

                __source="${__workspace}/bin"
                FS_Is_Directory_Empty "$__source"
                if [ $? -ne 0 ]; then
                        ## write the opener
                        FS_Append_File "$__dest" "\
                        <!-- Compulsory Executable Here -->
                        <Directory Id='FolderBin' Name='bin'>
                                <Component Id='${PROJECT_MSI_BIN_COMPONENT_ID}'
                                        Guid='${PROJECT_MSI_BIN_COMPONENT_GUID}'
                                >
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi

                        ## loop through each file and create the following
                        for __file in "${__source}/"*; do
                                FS_Is_File "$__file"
                                if [ $? -ne 0 ]; then
                                        continue
                                fi

                                FS_Append_File "$__dest" "\
                                        <File Id='Bin_$(RANDOM_Create_STRING "33")'
                                                Source='${__file}'
                                        />
"
                                if [ $? -ne 0 ]; then
                                        I18N_Create_Failed
                                        return 1
                                fi
                        done

                        ## write the closure
                        FS_Append_File "$__dest" "\
                                </Component>
                        </Directory>
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi

                fi

                __source="${__workspace}/config"
                FS_Is_Directory_Empty "$__source"
                if [ $? -ne 0 ]; then
                        ## write the opener
                        FS_Append_File "$__dest" "\
                        <!-- Compulsory Configurations Here -->
                        <Directory Id='FolderConfig' Name='config'>
                                <Component Id='${PROJECT_MSI_CONFIG_COMPONENT_ID}'
                                        Guid='${PROJECT_MSI_CONFIG_COMPONENT_GUID}'
                                >
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi

                        ## loop through each file and create the following
                        for __file in "${__source}/"*; do
                                FS_Is_File "$__file"
                                if [ $? -ne 0 ]; then
                                        continue
                                fi

                                FS_Append_File "$__dest" "\
                                        <File Id='Config_$(RANDOM_Create_STRING "33")'
                                                Source='${__file}'
                                        />
"
                                if [ $? -ne 0 ]; then
                                        I18N_Create_Failed
                                        return 1
                                fi
                        done

                        ## write the closure
                        FS_Append_File "$__dest" "\
                                </Component>
                        </Directory>
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi

                fi

                __source="${__workspace}/lib"
                FS_Is_Directory_Empty "$__source"
                if [ $? -ne 0 ]; then
                        ## write the opener
                        FS_Append_File "$__dest" "\
                        <!-- Compulsory Libraries Files Here -->
                        <Directory Id='FolderLib' Name='lib'>
                                <Component Id='${PROJECT_MSI_LIB_COMPONENT_ID}'
                                        Guid='${PROJECT_MSI_LIB_COMPONENT_GUID}'
                                >
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi

                        ## loop through each file and create the following
                        for __file in "${__source}/"*; do
                                FS_Is_File "$__file"
                                if [ $? -ne 0 ]; then
                                        continue
                                fi

                                FS_Append_File "$__dest" "\
                                        <File Id='Lib_$(RANDOM_Create_STRING "33")'
                                                Source='${__file}'
                                        />
"
                                if [ $? -ne 0 ]; then
                                        I18N_Create_Failed
                                        return 1
                                fi
                        done

                        ## write the closure
                        FS_Append_File "$__dest" "\
                                </Component>
                        </Directory>
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi

                fi

                __source="${__workspace}/docs"
                FS_Is_Directory_Empty "$__source"
                if [ $? -ne 0 ]; then
                        ## write the opener
                        FS_Append_File "$__dest" "\
                        <!-- Compulsory Docs Files Here -->
                        <Component Id='${PROJECT_MSI_DOCS_COMPONENT_ID}'
                                Guid='${PROJECT_MSI_DOCS_COMPONENT_GUID}'
                        >
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi

                        ## loop through each file and create the following
                        for __file in "${__source}/"*; do
                                FS_Is_File "$__file"
                                if [ $? -ne 0 ]; then
                                        continue
                                fi

                                FS_Append_File "$__dest" "\
                                <File Id='Docs_$(RANDOM_Create_STRING "33")'
                                        Source='${__file}'
                                />
"
                                if [ $? -ne 0 ]; then
                                        I18N_Create_Failed
                                        return 1
                                fi
                        done

                        ## write the closure
                        FS_Append_File "$__dest" "\
                        </Component>
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi

                fi


                # close directory section
                FS_Append_File "$__dest" "\
                </Directory></Directory></Directory>
                        <Component Id='${PROJECT_MSI_REGISTRIES_ID}'
                                Guid='${PROJECT_MSI_REGISTRIES_GUID}'
                        >
                                <RegistryKey Root='HKLM'
                                        Key='${PROJECT_MSI_REGISTRY_KEY}'
                                >
                                        <!-- IMPORTANT NOTE: DO NOT REMOVE this default entry -->
                                        <RegistryValue
                                                Name='${PROJECT_MSI_REGISTRY_NAME}'
                                                Value='[${PROJECT_MSI_INSTALL_DIRECTORY}]'
                                                Type='string'
                                                KeyPath='yes'
                                        />
                                        <!-- IMPORTANT NOTE:                                 -->
                                        <!--     DO NOT use default registries here.         -->
                                        <!--     They are removable by uninstall/upgrade.    -->
                                        <!--     Use %APPDATA% and etc instead.              -->
                                </RegistryKey>
                        </Component>
                </Directory>
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi


                # define all feature components
                FS_Append_File "$__dest" "\
                <Feature Id='${PROJECT_MSI_FEATURES_ID}'
                        Title='$(hestiaI18N_Translate_All_Components_Title "$__language")'
                        Description='$(hestiaI18N_Translate_All_Components_Description \
                                                "$__language")'
                        Level='1'
                        Display='expand'
                        ConfigurableDirectory='${PROJECT_MSI_INSTALL_DIRECTORY}'
                >
                        <Feature Id='${PROJECT_MSI_MAIN_FEATURE_ID}'
                                Title='$(hestiaI18N_Translate_Main_Components_Title \
                                                "$__language")'
                                Description='$(hestiaI18N_Translate_Main_Components_Description \
                                                     "$__language")'
                                Level='1'
                        >
                                <ComponentRef Id='${PROJECT_MSI_REGISTRIES_ID}' />
                        </Feature>
"
                        if [ $? -ne 0 ]; then
                                I18N_Create_Failed
                                return 1
                        fi


                        # write bin feature list
                        FS_Is_Directory_Empty "${__workspace}/bin"
                        if [ $? -ne 0 ]; then
                                FS_Append_File "$__dest" "\
                        <Feature Id='${PROJECT_MSI_BIN_FEATURE_ID}'
                                Title='$(hestiaI18N_Translate_Bin_Components_Title \
                                                "$__language")'
                                Description='$(hestiaI18N_Translate_Bin_Components_Description \
                                                     "$__language")'
                                Level='1'
                        >
                                <ComponentRef Id='${PROJECT_MSI_BIN_COMPONENT_ID}' />
                        </Feature>
"
                                if [ $? -ne 0 ]; then
                                        I18N_Create_Failed
                                        return 1
                                fi
                        fi


                        # write config feature list
                        FS_Is_Directory_Empty "${__workspace}/config"
                        if [ $? -ne 0 ]; then
                                FS_Append_File "$__dest" "\
                        <Feature Id='${PROJECT_MSI_CONFIG_FEATURE_ID}'
                                Title='$(hestiaI18N_Translate_Config_Components_Title \
                                                "$__language")'
                                Description='$(hestiaI18N_Translate_Config_Components_Description \
                                                     "$__language")'
                                Level='1'
                        >
                                <ComponentRef Id='${PROJECT_MSI_CONFIG_COMPONENT_ID}' />
                        </Feature>
"
                                if [ $? -ne 0 ]; then
                                        I18N_Create_Failed
                                        return 1
                                fi
                        fi


                        # write lib feature list
                        FS_Is_Directory_Empty "${__workspace}/lib"
                        if [ $? -ne 0 ]; then
                                FS_Append_File "$__dest" "\
                        <Feature Id='${PROJECT_MSI_LIB_FEATURE_ID}'
                                Title='$(hestiaI18N_Translate_Lib_Components_Title \
                                                "$__language")'
                                Description='$(hestiaI18N_Translate_Lib_Components_Description \
                                                     "$__language")'
                                Level='1'
                        >
                                <ComponentRef Id='${PROJECT_MSI_LIB_COMPONENT_ID}' />
                        </Feature>
"
                                if [ $? -ne 0 ]; then
                                        I18N_Create_Failed
                                        return 1
                                fi
                        fi


                        # write docs feature list
                        FS_Is_Directory_Empty "${__workspace}/docs"
                        if [ $? -ne 0 ]; then
                                FS_Append_File "$__dest" "\
                        <Feature Id='${PROJECT_MSI_DOCS_FEATURE_ID}'
                                Title='$(hestiaI18N_Translate_Docs_Components_Title \
                                                "$__language")'
                                Description='$(hestiaI18N_Translate_Docs_Components_Description \
                                                     "$__language")'
                                Level='1'
                        >
                                <ComponentRef Id='${PROJECT_MSI_DOCS_COMPONENT_ID}' />
                        </Feature>
"
                                if [ $? -ne 0 ]; then
                                        I18N_Create_Failed
                                        return 1
                                fi
                        fi


                # close feature list
                FS_Append_File "$__dest" "\
                </Feature>
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi


                # conclude the wxs write-up
                FS_Append_File "$__dest" "\
        </Product>
</Wix>
"
                if [ $? -ne 0 ]; then
                        I18N_Create_Failed
                        return 1
                fi


                # begin packaging
                I18N_Package "$__dest"
                MSI_Compile "$__dest" "$_target_arch" "$__language"
                if [ $? -ne 0 ]; then
                        I18N_Package_Failed
                        return 1
                fi
        done <<EOF
$(hestiaI18N_Get_Languages_List)
EOF


        # begin export packages
        __old_IFS="$IFS"
        while IFS= read -r __line || [ -n "$__line" ]; do
                FS_Is_File "$__line"
                if [ $? -ne 0 ]; then
                        continue
                fi

                __dest="${__output_directory}/$(FS_Get_File "$__line")"
                I18N_Export "$__dest"
                FS_Copy_File "$__line" "$__dest"
                if [ $? -ne 0 ]; then
                        I18N_Export_Failed
                        return 1
                fi
        done <<EOF
$(find "$__workspace" -type f -name '*.msi')
EOF
        IFS="$__old_IFS" && unset __old_IFS


        # report status
        return 0
}




PACKAGE_Sort_MSI() {
        __workspace="$1"


        # execute
        __source="${__workspace}/any"
        I18N_Check "$__source"
        FS_Is_Directory "$__source"
        if [ $? -ne 0 ]; then
                return 0 # nothing to sort - report status
        fi


        for _arch in "${__workspace}/"*; do
                FS_Is_Directory "$_arch"
                if [ $? -ne 0 ]; then
                        continue
                fi

                if [ "$(FS_Get_File "$_arch")" = "any" ]; then
                        continue
                fi

                # begin merging from any
                for __target in "${__workspace}/any"/*; do
                        FS_Is_File "$__target"
                        if [ $? -eq 0 ]; then
                                __dest="$(FS_Get_File "$__target")"
                                __dest="${_arch}/${__dest}"
                                I18N_Copy "$__target" "$__dest"
                                FS_Is_File "$__dest"
                                if [ $? -eq 0 ]; then
                                        I18N_Copy_Exists_Skipped
                                        continue # do not overwrite
                                fi

                                FS_Copy_File "$__target" "$__dest"
                                if [ $? -ne 0 ]; then
                                        I18N_Copy_Failed
                                        return 1
                                fi

                                continue
                        fi

                        ## it's a directory, loop it
                        for __file in "${__target}/"*; do
                                FS_Is_File "$__file"
                                if [ $? -ne 0 ]; then
                                        continue
                                fi

                                __dest="$(FS_Get_File "$__file")"
                                __dest="${_arch}/$(FS_Get_File "$__target")/${__dest}"
                                I18N_Copy "$__file" "$__dest"
                                FS_Is_File "$__dest"
                                if [ $? -eq 0 ]; then
                                        I18N_Copy_Exists_Skipped
                                        continue # do not overwrite
                                fi

                                FS_Copy_File "$__file" "$__dest"
                                if [ $? -ne 0 ]; then
                                        I18N_Copy_Failed
                                        return 1
                                fi
                        done
                done
        done


        # remove any to prevent bad compilation
        FS_Remove "${__workspace}/any"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi


        # report status
        return 0
}



PACKAGE_Run_MSI() {
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

        _src="${__line%%|*}"


        # validate input
        I18N_Check_Availability "MSI"
        MSI_Is_Available
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 0
        fi


        # prepare workspace and required values
        I18N_Create_Package "MSI"
        _src="${_src}/${_target_arch}"
        FS_Make_Directory "${_src}/bin"
        FS_Make_Directory "${_src}/config"
        FS_Make_Directory "${_src}/docs"
        FS_Make_Directory "${_src}/ext"
        FS_Make_Directory "${_src}/lib"


        # copy all complimentary files to the workspace
        cmd="PACKAGE_Assemble_MSI_Content"
        I18N_Check_Function "$cmd"
        OS_Is_Command_Available "$cmd"
        if [ $? -ne 0 ]; then
                I18N_Check_Failed
                return 1
        fi

        I18N_Assemble_Package
        PACKAGE_Assemble_MSI_Content \
                "$_target" \
                "$_src" \
                "$_target_filename" \
                "$_target_os" \
                "$_target_arch"
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


        # report status
        return 0
}
