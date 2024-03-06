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
if (-not (Test-Path -Path $env:PROJECT_PATH_ROOT)) {
	Write-Error "[ ERROR ] - Please run from automataCI\ci.sh.ps1 instead!`n"
	exit 1
}

. "${env:LIBS_AUTOMATACI}\services\io\fs.ps1"
. "${env:LIBS_AUTOMATACI}\services\io\strings.ps1"
. "${env:LIBS_AUTOMATACI}\services\i18n\translations.ps1"
. "${env:LIBS_AUTOMATACI}\services\crypto\random.ps1"
. "${env:LIBS_AUTOMATACI}\services\publishers\dotnet.ps1"




function PACKAGE-Assemble-MSI-Content {
	param (
		[string]$_target,
		[string]$_directory,
		[string]$_target_name,
		[string]$_target_os,
		[string]$_target_arch
	)


	# package based on target's nature
	if ($(FS-Is-Target-A-MSI "${_target}") -ne 0) {
		return 10 # not applicable
	}


	# validate critical inputs
	if ($(STRINGS-Is-Empty "${env:PRODUCT_APP_UUID}") -eq 0) {
		return 1
	}


	# configure packaging settings
	$__build_path = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_BUILD}"
	$__source_path = "${env:PROJECT_PATH_ROOT}\${env:PROJECT_PATH_SOURCE}"
	$__files = @(
		"${__build_path}\${env:PROJECT_SKU}_windows-amd64.exe|none"
		"${__build_path}\${env:PROJECT_SKU}_windows-arm64.exe|none"
		"${__build_path}\${env:PROJECT_SKU}_windows-i386.exe|none"
		"${__build_path}\${env:PROJECT_SKU}_windows-arm.exe|none"
		"${__source_path}\licenses\LICENSE_en.rtf|LICENSE_en.rtf"
		"${__source_path}\licenses\LICENSE_en.rtf|LICENSE_zh-hans.rtf"
		"${__source_path}\licenses\LICENSE-EN.pdf|LICENSE_en.pdf"
		"${__source_path}\licenses\LICENSE-EN.pdf|LICENSE_zh-hans.pdf"
		"${__source_path}\docs\USER-GUIDES-EN.pdf|USER-GUIDES_en.pdf"
		"${__source_path}\docs\USER-GUIDES-EN.pdf|USER-GUIDES_zh-hans.pdf"
		"${__source_path}\icons\icon.ico|none"
		"${__source_path}\icons\msi-banner_en.jpg|none"
		"${__source_path}\icons\msi-banner_zh-hans.jpg|none"
		"${__source_path}\icons\msi-dialog_en.jpg|none"
		"${__source_path}\icons\msi-dialog_zh-hans.jpg|none"
	)
	$__selections = @(
		"amd64|en"
		"amd64|zh-hans"
		"arm64|en"
		"arm64|zh-hans"
	)


	# download required UI extensions
	$__toolkit_ui = 'WixToolset.UI.wixext'
	$___process = DOTNET-Add `
		"${__toolkit_ui}" `
		"4.0.3" `
		"${_directory}\ext" `
		"wixext4\${__toolkit_ui}.dll"
	if ($___process -ne 0) {
		return 1
	}


	# Assemble all files across all languages. Checking is not required
	# since it will be checked during the scripting phase.
	foreach ($__line in $__files) {
		## parse line
		$__list = $__line -split "\|"
		$__target = $__list[0]
		$__dest = $__list[1]

		## validate inputs
		if (($(STRINGS-Is-Empty "${__dest}") -ne 0) -and ("${__dest}" -ne "none")) {
			$__dest = "${_directory}\${__dest}"
		} else {
			$__dest = "${_directory}"
		}

		## execute
		$null = I18N-Assemble "${__target}" "${__dest}"
		if (Test-Path "${__target}") {
			$null = FS-Copy-File "${__target}" "${__dest}" `
				-ErrorAction SilentlyContinue
		}
	}


	# generate all arch & i18n independent variables and tags
	$__tag_ICON = 'Icon.exe'
	$__const_ICON_SOURCE = "${_directory}\icon.ico"

	$__tag_DIR_INSTALL = 'INSTALLDIR'
	$__tag_ARP_INSTALL_LOCATION = 'ARPINSTALLLOCATION'
	$__const_INSTALLER_VERSION = '500'
	$__const_INSTALLER_COMPRESSED_MODE = 'yes' # 'yes'|'no' only
	$__const_INSTALLER_CODEPAGE = '65001' # UTF-8
	$__const_INSTALLER_INSTALL_SCOPE = 'perMachine'
	$__const_INSTALLER_REGISTRY_KEY = @"
Software\\\\${env:PROJECT_CONTACT_NAME}\\\\InstalledProducts\\\\${env:PROJECT_NAME}
"@
	$__const_INSTALLER_REGISTRY_NAME = 'InstallLocation'

	$__tag_COMPONENT_BIN = 'ComponentBin'
	$__uuid_COMPONENT_BIN = RANDOM-Create-UUID # replace with persistent one
	$__tag_COMPONENT_BIN_OPTIONAL = 'ComponentBinOptional'
	$__uuid_COMPONENT_BIN_OPTIONAL = Random-Create-UUID # replace with persistent one
	$__tag_COMPONENT_CONFIG = 'ComponentConfig'
	$__uuid_COMPONENT_CONFIG = RANDOM-Create-UUID # replace with persistent one
	$__tag_COMPONENT_CONFIG_OPTIONAL = 'ComponentConfigOptional'
	$__uuid_COMPONENT_CONFIG_OPTIONAL = RANDOM-Create-UUID # replace with persistent one
	$__tag_COMPONENT_LIB = 'ComponentLib'
	$__uuid_COMPONENT_LIB = RANDOM-Create-UUID # replace with persistent one
	$__tag_COMPONENT_LIB_OPTIONAL = 'ComponentLibOptional'
	$__uuid_COMPONENT_LIB_OPTIONAL = RANDOM-Create-UUID # replace with persistent one
	$__tag_COMPONENT_DOCS = 'ComponentDocs'
	$__uuid_COMPONENT_DOCS = RANDOM-Create-UUID # replace with persistent one
	$__tag_COMPONENT_DOCS_OPTIONAL = 'ComponentDocsOptional'
	$__uuid_COMPONENT_DOCS_OPTIONAL = RANDOM-Create-UUID # replace with persistent one

	$__tag_COMPONENT_INSTALLER = 'INSTALLDIR_comp'
	$__uuid_COMPONENT_INSTALLER = RANDOM-Create-UUID # replace with persistent one
	$__tag_COMPONENT_REGISTRIES = 'ComponentRegistries'
	$__uuid_COMPONENT_REGISTRIES = RANDOM-Create-UUID # replace with persistent one

	$__tag_FEATURE_ID = 'FeaturesAll'
	$__tag_FEATURE_MAIN_ID = 'FeaturesMain'
	$__tag_FEATURE_BIN_ID = 'FeaturesBin'
	$__tag_FEATURE_CONFIG_ID = 'FeaturesConfig'
	$__tag_FEATURE_LIB_ID = 'FeaturesLib'
	$__tag_FEATURE_DOCS_ID = 'FeaturesDocs'

	$__const_OPTIONALITY = " AllowAbsent='yes'"
	$__const_DIR_PROGRAM_FILES = "ProgramFiles6432Folder"


	# script the .wxs XML file
	foreach ($__line in $__selections) {
		# parse line
		$__list = $__line -split "\|"
		$__arch = STRINGS-To-Lowercase $__list[0]
		$__i18n = STRINGS-To-Lowercase $__list[1]


		# generate all arch-specific variables and validate readiness for compilation
		switch ($__arch) {
		amd64 {
			$__var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE = @"
Unfortunately, you can only install this package on a 64-bit Windows.
"@
			$__var_INSTALLER_REQUIRED_VERSION_CONDITION = "VersionNT64"
		} arm64 {
			$__var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE = @"
Unfortunately, you can only install this package on a 64-bit Windows.
"@
			$__var_INSTALLER_REQUIRED_VERSION_CONDITION = "VersionNT64"
		} i386 {
			$__var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE = @"
Unfortunately, you can only install this package on a 32-bit Windows.
"@
			$__var_INSTALLER_REQUIRED_VERSION_CONDITION = "Not VersionNT64"
		} arm {
			$__var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE = @"
Unfortunately, you can only install this package on a 32-bit Windows.
"@
			$__var_INSTALLER_REQUIRED_VERSION_CONDITION = "Not VersionNT64"
		} default {
			return 1
		}}


		# check required executables for packaging
		$__var_MAIN_EXE_SOURCE = "${_directory}\${env:PROJECT_SKU}_windows-${__arch}.exe"
		$null = I18N-Check "${__var_MAIN_EXE_SOURCE}"
		$___process = FS-Is-File "${__var_MAIN_EXE_SOURCE}"
		if ($___process -ne 0) {
			$null = I18N-Check-Failed-Skipped
			continue
		}


		# generate all i18n variables and validate readiness for compilation
		$_wxs = "${env:PROJECT_SKU}_${env:PROJECT_VERSION}"
		switch ($__i18n) {
		zh-hans {
			## Simplified Chinese (International)
			$__i18n = "zh-hans"

			## NOTE: MSFT uses LCID instead of ISO indicator. Refer:
			##       https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/70feba9f-294e-491e-b6eb-56532684c37f
			$__var_LANGUAGE_ID = '2052'

			## NOTE: DO NOT change the format. AutomataCI relies on
			##       it to parse wix4 culture settings.
			##       https://wixtoolset.org/docs/tools/wixext/wixui/#localization
			$_wxs = "${_wxs}_zh-cn"

			$__var_INSTALLER_DESCRIPTION = @"
${env:PROJECT_NAME} (${env:PROJECT_VERSION}) 安装包
"@
			$__var_INSTALLER_COMMENTS = "(C) ${env:PROJECT_CONTACT_NAME}"
			$__var_INSTALLER_BANNER_SOURCE = "${_directory}\msi-banner_${__i18n}.jpg"
			$__var_INSTALLER_DIALOG_SOURCE = "${_directory}\msi-dialog_${__i18n}.jpg"
			$__var_INSTALLER_DOWNGRADE_COMMENT = @"
您的${env:PROJECT_NAME}已经是同样|更新版本。如此就不需要任何步骤了。谢谢。
"@
			$__var_MAIN_LICENSE_SOURCE = "${_directory}\LICENSE_zh-hans.pdf"

			$__var_USER_GUIDE_ID = 'DocsUserGuideZHHANS'
			$__var_USER_GUIDE_SOURCE = "${_directory}\USER-GUIDES_zh-hans.pdf"

			$__var_FEATURE_TITLE = "${env:PROJECT_NAME}"
			$__var_FEATURE_DESCRIPTION = '完整全部包装。'

			$__var_FEATURE_MAIN_TITLE = '主要元件配套'
			$__var_FEATURE_MAIN_DESCRIPTION = '所有第一重要无法缺乏的元件。'

			$__var_FEATURE_BIN_TITLE = '软件类元件配套'
			$__var_FEATURE_BIN_DESCRIPTION = '所有可有可无的可多加软件类元件。'

			$__var_FEATURE_CONFIG_TITLE = '配置类元件配套'
			$__var_FEATURE_CONFIG_DESCRIPTION = '所有可有可无的可多加配置类元件。'

			$__var_FEATURE_LIB_TITLE = '代码库类元件配套'
			$__var_FEATURE_LIB_DESCRIPTION = '所有可有可无的可多加代码库类元件。'

			$__var_FEATURE_DOCS_TITLE = '文件类元件配套'
			$__var_FEATURE_DOCS_DESCRIPTION = '所有可有可无的可多加文件类元件。'
		} default {
			## default to English (International)
			$__i18n = "en"

			## NOTE: MSFT uses LCID instead of ISO indicator. Refer:
			##       https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/70feba9f-294e-491e-b6eb-56532684c37f
			$__var_LANGUAGE_ID = '1033'

			## NOTE: DO NOT change the format. AutomataCI relies on
			##       it to parse wix4 culture settings. Refer:
			##       https://wixtoolset.org/docs/tools/wixext/wixui/#localization
			$_wxs = "${_wxs}_en-us"

			$__var_INSTALLER_DESCRIPTION=@"
${env:PROJECT_NAME} (${env:PROJECT_VERSION}) Installer
"@
			$__var_INSTALLER_COMMENTS = "(C) ${env:PROJECT_CONTACT_NAME}"

			$__var_INSTALLER_BANNER_SOURCE = "${_directory}\msi-banner_${__i18n}.jpg"
			$__var_INSTALLER_DIALOG_SOURCE = "${_directory}\msi-dialog_${__i18n}.jpg"

			$__var_INSTALLER_DOWNGRADE_COMMENT = @"
Your ${env:PROJECT_NAME} is the same/later version. No further action is required. Thank you.
"@

			$__var_MAIN_LICENSE_SOURCE = "${_directory}\LICENSE_en.pdf"

			$__var_USER_GUIDE_ID = 'DocsUserGuideEN'
			$__var_USER_GUIDE_SOURCE = "${_directory}\USER-GUIDES_en.pdf"

			$__var_FEATURE_TITLE = "${env:PROJECT_NAME}"
			$__var_FEATURE_DESCRIPTION = 'The complete package.'

			$__var_FEATURE_MAIN_TITLE = 'Main Components'
			$__var_FEATURE_MAIN_DESCRIPTION = 'All core and critical components.'

			$__var_FEATURE_BIN_TITLE = 'Additional Components'
			$__var_FEATURE_BIN_DESCRIPTION = 'All optional addition components.'

			$__var_FEATURE_CONFIG_TITLE = 'Additional Configurations Components'
			$__var_FEATURE_CONFIG_DESCRIPTION = 'All optional configurations components.'

			$__var_FEATURE_LIB_TITLE = 'Additional Libraries Components'
			$__var_FEATURE_LIB_DESCRIPTION = 'All optional libraries components.'

			$__var_FEATURE_DOCS_TITLE = 'Documentation Components'
			$__var_FEATURE_DOCS_DESCRIPTION = 'All documentations components.'
		}}
		$__var_UI_LICENSE_SOURCE = "${_directory}\LICENSE_${__i18n}.rtf"
		$_wxs = "${_directory}\${_wxs}_windows-${__arch}.wxs"


		# check required files for packaging
		$null = I18N-Check "${__var_MAIN_LICENSE_SOURCE}"
		$___process = FS-Is-File "${__var_MAIN_LICENSE_SOURCE}"
		if ($___process -ne 0) {
			$null = I18N-Check-Failed-Skipped
			continue
		}

		$null = I18N-Check "${__var_USER_GUIDE_SOURCE}"
		$___process = FS-Is-File "${__var_USER_GUIDE_SOURCE}"
		if ($___process -ne 0) {
			$null = I18N-Check-Failed-Skipped
			continue
		}

		$null = I18N-Check "${__var_UI_LICENSE_SOURCE}"
		$___process = FS-Is-File "${__var_UI_LICENSE_SOURCE}"
		if ($___process -ne 0) {
			$null = I18N-Check-Failed-Skipped
			continue
		}

		$null = I18N-Check "${_wxs}"
		if (Test-Path "${_wxs}") {
			$null = I18N-Check-Failed
			return 1
		}


		# creating wxs recipe
		$null = I18N-Create "${_wxs}"
		$___process = FS-Write-File "${_wxs}" @"
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs"
	xmlns:ui="http://wixtoolset.org/schemas/v4/wxs/ui"
>
	<Package Name='${env:PROJECT_NAME}'
		Language='${__var_LANGUAGE_ID}'
		Version='${env:PROJECT_VERSION}'
		Manufacturer='${env:PROJECT_CONTACT_NAME}'
		UpgradeCode='${env:PRODUCT_APP_UUID}'
		InstallerVersion='${__const_INSTALLER_VERSION}'
		Compressed='${__const_INSTALLER_COMPRESSED_MODE}'
		Codepage='${__const_INSTALLER_CODEPAGE}'
	>
		<SummaryInformation
			Keywords='Installer'
			Description='${__var_INSTALLER_DESCRIPTION}'
		/>
		<Icon Id='${__tag_ICON}' SourceFile='${__const_ICON_SOURCE}' />
		<MajorUpgrade AllowSameVersionUpgrades='yes'
			DowngradeErrorMessage='${__var_INSTALLER_DOWNGRADE_COMMENT}'
		/>

		<!-- Configure 'Add/Remove Programs' interfaces -->
		<Property Id='ARPPRODUCTICON' Value='${__tag_ICON}' />
		<Property Id='ARPHELPLINK' Value='${env:PROJECT_CONTACT_WEBSITE}' />
		<Property Id='ARPNOREPAIR' Value='yes' Secure='yes' /><!-- Remove repair -->
		<Property Id='ARPNOMODIFY' Value='yes' Secure='yes' /><!-- Remove modify -->

		<!-- Configure installer main sequences -->
		<CustomAction Id='Wix4Set${__tag_ARP_INSTALL_LOCATION}_X86'
			Property='${__tag_ARP_INSTALL_LOCATION}'
			Value='[${__tag_DIR_INSTALL}]' />
		<CustomAction Id='Wix4Set${__tag_ARP_INSTALL_LOCATION}_X64'
			Property='${__tag_ARP_INSTALL_LOCATION}'
			Value='[${__tag_DIR_INSTALL}]' />
		<CustomAction Id='Wix4Set${__tag_ARP_INSTALL_LOCATION}_A64'
			Property='${__tag_ARP_INSTALL_LOCATION}'
			Value='[${__tag_DIR_INSTALL}]' />
		<InstallExecuteSequence>
			<!-- Determine the install location after validated by the installer -->
			<Custom Action='Wix4Set${__tag_ARP_INSTALL_LOCATION}_X86'
				After='InstallValidate'
			></Custom>
			<Custom Action='Wix4Set${__tag_ARP_INSTALL_LOCATION}_X64'
				After='InstallValidate'
			></Custom>
			<Custom Action='Wix4Set${__tag_ARP_INSTALL_LOCATION}_A64'
				After='InstallValidate'
			></Custom>
		</InstallExecuteSequence>

		<!-- Configure backward compatible multi-mediums (e.g. Floppy disks, CDs) -->
		<Media Id='1' Cabinet='media1.cab' EmbedCab='yes' />

		<!-- Configure installer launch condition -->
		<Launch Condition='${__var_INSTALLER_REQUIRED_VERSION_CONDITION}'
			Message='${__var_INSTALLER_REQUIRED_VERSION_ERROR_MESSAGE}' />

		<!-- Configure ${__tag_DIR_INSTALL} from CMD -->
		<CustomAction Id='Wix4SaveCMD${__tag_DIR_INSTALL}_X86'
			Property='CMDLINE_${__tag_DIR_INSTALL}'
			Value='[${__tag_DIR_INSTALL}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SetFromCMD${__tag_DIR_INSTALL}_X86'
			Property='${__tag_DIR_INSTALL}'
			Value='[${__tag_DIR_INSTALL}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SaveCMD${__tag_DIR_INSTALL}_X64'
			Property='CMDLINE_${__tag_DIR_INSTALL}'
			Value='[${__tag_DIR_INSTALL}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SetFromCMD${__tag_DIR_INSTALL}_X64'
			Property='${__tag_DIR_INSTALL}'
			Value='[${__tag_DIR_INSTALL}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SaveCMD${__tag_DIR_INSTALL}_A64'
			Property='CMDLINE_${__tag_DIR_INSTALL}'
			Value='[${__tag_DIR_INSTALL}]'
			Execute='firstSequence'
		/>
		<CustomAction Id='Wix4SetFromCMD${__tag_DIR_INSTALL}_A64'
			Property='${__tag_DIR_INSTALL}'
			Value='[${__tag_DIR_INSTALL}]'
			Execute='firstSequence'
		/>
		<InstallUISequence>
			<Custom Action='Wix4SaveCMD${__tag_DIR_INSTALL}_X86'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${__tag_DIR_INSTALL}_X86'
				After='AppSearch'
				Condition='CMDLINE_${__tag_DIR_INSTALL}'
			/>
			<Custom Action='Wix4SaveCMD${__tag_DIR_INSTALL}_X64'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${__tag_DIR_INSTALL}_X64'
				After='AppSearch'
				Condition='CMDLINE_${__tag_DIR_INSTALL}'
			/>
			<Custom Action='Wix4SaveCMD${__tag_DIR_INSTALL}_A64'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${__tag_DIR_INSTALL}_A64'
				After='AppSearch'
				Condition='CMDLINE_${__tag_DIR_INSTALL}'
			/>
		</InstallUISequence>
		<InstallExecuteSequence>
			<Custom Action='Wix4SaveCMD${__tag_DIR_INSTALL}_X86'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${__tag_DIR_INSTALL}_X86'
				After='AppSearch'
				Condition='CMDLINE_${__tag_DIR_INSTALL}'
			/>
			<Custom Action='Wix4SaveCMD${__tag_DIR_INSTALL}_X64'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${__tag_DIR_INSTALL}_X64'
				After='AppSearch'
				Condition='CMDLINE_${__tag_DIR_INSTALL}'
			/>
			<Custom Action='Wix4SaveCMD${__tag_DIR_INSTALL}_A64'
				Before='AppSearch' />
			<Custom Action='Wix4SetFromCMD${__tag_DIR_INSTALL}_A64'
				After='AppSearch'
				Condition='CMDLINE_${__tag_DIR_INSTALL}'
			/>
		</InstallExecuteSequence>

		<Property Id='${__tag_DIR_INSTALL}'>
			<RegistrySearch Id='DetermineInstallLocation'
				Type='raw'
				Root='HKLM'
				Key='${__const_INSTALLER_REGISTRY_KEY}'
				Name='${__const_INSTALLER_REGISTRY_NAME}'
			/>
		</Property>

		<!-- Uninstallation component -->
		<Component Id='${__tag_COMPONENT_INSTALLER}'
			Guid='${__uuid_COMPONENT_INSTALLER}'
			Directory='${__tag_DIR_INSTALL}'
		>
			<CreateFolder />
			<RemoveFile Id='RemoveFilesFromAppDirectory'
				Name='*.*'
				On='uninstall' />
		</Component>


"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# Define filesystem
		$___process = FS-Append-File "${_wxs}" @"
		<StandardDirectory Id='${__const_DIR_PROGRAM_FILES}'>
			<Directory Id='${__tag_DIR_INSTALL}' Name='${env:PROJECT_NAME}'>
				<Directory Id='${__tag_DIR_INSTALL}Bin' Name='bin'>
				</Directory>
				<Directory Id='${__tag_DIR_INSTALL}Config' Name='config'>
				</Directory>
				<Directory Id='${__tag_DIR_INSTALL}Lib' Name='lib'>
				</Directory>
				<Directory Id='${__tag_DIR_INSTALL}Docs' Name='docs'>
				</Directory>
			</Directory>
		</StandardDirectory>


"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		## BEGIN - Assemble components
		$___process = FS-Append-File "${_wxs}" @"
		<ComponentGroup Id='ProductExecutables' Directory='${__tag_DIR_INSTALL}Bin'>
			<!-- Compulsory Executable Here -->
			<Component Id='${__tag_COMPONENT_BIN}' Guid='${__uuid_COMPONENT_BIN}'>
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
		</ComponentGroup>


		<ComponentGroup Id='ProductConfigs' Directory='${__tag_DIR_INSTALL}Config'>
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
		</ComponentGroup>


		<ComponentGroup Id='ProductLibs' Directory='${__tag_DIR_INSTALL}Lib'>
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
		</ComponentGroup>


		<ComponentGroup Id='ProductDocs' Directory='${__tag_DIR_INSTALL}Docs'>
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
		</ComponentGroup>


"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# create registry key
		$___process = FS-Append-File "${_wxs}" @"
		<Component Id='${__tag_COMPONENT_REGISTRIES}'
			Guid='${__uuid_COMPONENT_REGISTRIES}'
			Directory='${__tag_DIR_INSTALL}'
		><RegistryKey Root='HKLM' Key='${__const_INSTALLER_REGISTRY_KEY}'>
			<!-- DO NOT REMOVE this default entry -->
			<RegistryValue
				Name='${__const_INSTALLER_REGISTRY_NAME}'
				Value='[${__tag_DIR_INSTALL}]'
				Type='string'
				KeyPath='yes'
			/>

			<!-- DO NOT use the application's variable registries here -->
			<!-- They will be removed upon uninstall (as in during upgrade run) -->
			<!-- For those, use %APPDATA% and etc instead. -->
			<!-- Otherwise, refer the above compulsory entry to add more. -->
		</RegistryKey></Component>


"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# Define all feature components
		$___process = FS-Append-File "${_wxs}" @"
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
				<ComponentRef Id='INSTALLDIR_comp' />
				<ComponentRef Id='${__tag_COMPONENT_REGISTRIES}' />
				<ComponentRef Id='${__tag_COMPONENT_BIN}' />
				<ComponentRef Id='${__tag_COMPONENT_CONFIG}' />
				<ComponentRef Id='${__tag_COMPONENT_LIB}' />
				<ComponentRef Id='${__tag_COMPONENT_DOCS}' />
			</Feature>
			<Feature Id='${__tag_FEATURE_BIN_ID}'${__const_OPTIONALITY}
				Title='${__var_FEATURE_BIN_TITLE}'
				Description='${__var_FEATURE_BIN_DESCRIPTION}'
				Level='1'
			>
				<ComponentRef Id='${__tag_COMPONENT_BIN_OPTIONAL}' />
			</Feature>
			<Feature Id='${__tag_FEATURE_CONFIG_ID}'${__const_OPTIONALITY}
				Title='${__var_FEATURE_CONFIG_TITLE}'
				Description='${__var_FEATURE_CONFIG_DESCRIPTION}'
				Level='1'
			>
				<ComponentRef Id='${__tag_COMPONENT_CONFIG_OPTIONAL}' />
			</Feature>
			<Feature Id='${__tag_FEATURE_LIB_ID}'${__const_OPTIONALITY}
				Title='${__var_FEATURE_LIB_TITLE}'
				Description='${__var_FEATURE_LIB_DESCRIPTION}'
				Level='1'
			>
				<ComponentRef Id='${__tag_COMPONENT_LIB_OPTIONAL}' />
			</Feature>
			<Feature Id='${__tag_FEATURE_DOCS_ID}'${__const_OPTIONALITY}
				Title='${__var_FEATURE_DOCS_TITLE}'
				Description='${__var_FEATURE_DOCS_DESCRIPTION}'
				Level='1'
			>
				<ComponentRef Id='${__tag_COMPONENT_DOCS_OPTIONAL}' />
			</Feature>
		</Feature>
"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# Add standard UI support
		$___process = FS-Append-File "${_wxs}" @"
		<!-- UI Customization -->
		<ui:WixUI Id='WixUI_FeatureTree' InstallDirectory='${__tag_DIR_INSTALL}' />
		<WixVariable Id='WixUIBannerBmp' Value='${__var_INSTALLER_BANNER_SOURCE}' />
		<WixVariable Id='WixUIDialogBmp' Value='${__var_INSTALLER_DIALOG_SOURCE}' />
		<WixVariable Id="WixUILicenseRtf" Value='${__var_UI_LICENSE_SOURCE}' />
"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}


		# conclude the wxs write-up
		$___process = FS-Append-File "${_wxs}" @"
	</Package>
</Wix>
"@
		if ($___process -ne 0) {
			$null = I18N-Create-Failed
			return 1
		}
	}


	# report status
	return 0
}
